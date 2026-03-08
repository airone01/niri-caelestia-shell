#include "networkmanager.hpp"

#include <NetworkManagerQt/Settings>
#include <NetworkManagerQt/ConnectionSettings>
#include <NetworkManagerQt/WirelessSetting>
#include <NetworkManagerQt/WirelessSecuritySetting>
#include <NetworkManagerQt/Ipv4Setting>
#include <NetworkManagerQt/Ipv6Setting>
#include <NetworkManagerQt/ActiveConnection>

#include <QDebug>
#include <QDBusPendingReply>

NetworkManagerProvider::NetworkManagerProvider(QObject* parent)
    : QObject(parent)
{
    connect(NetworkManager::notifier(), &NetworkManager::Notifier::wirelessEnabledChanged, this, &NetworkManagerProvider::updateWifiStatus);
    connect(NetworkManager::notifier(), &NetworkManager::Notifier::activeConnectionsChanged, this, &NetworkManagerProvider::updateConnectionStatus);
    connect(NetworkManager::notifier(), &NetworkManager::Notifier::deviceAdded, this, &NetworkManagerProvider::handleDeviceAdded);
    connect(NetworkManager::notifier(), &NetworkManager::Notifier::deviceRemoved, this, &NetworkManagerProvider::handleDeviceRemoved);
    
    // Initial fetch
    updateWifiStatus();
    updateConnectionStatus();
    
    m_scanTimer.setInterval(10000);
    m_scanTimer.setSingleShot(false);
    connect(&m_scanTimer, &QTimer::timeout, this, &NetworkManagerProvider::rescanWifi);
    m_scanTimer.start();
    
    for (const auto& dev : NetworkManager::networkInterfaces()) {
        handleDeviceAdded(dev->uni());
    }
}

bool NetworkManagerProvider::wifiEnabled() const {
    return NetworkManager::isWirelessEnabled();
}

void NetworkManagerProvider::setWifiEnabled(bool enabled) {
    if (NetworkManager::isWirelessEnabled() != enabled) {
        NetworkManager::setWirelessEnabled(enabled);
    }
}

bool NetworkManagerProvider::isConnected() const {
    return m_isConnected;
}

QString NetworkManagerProvider::activeConnection() const {
    return m_activeConnection;
}

QVariantList NetworkManagerProvider::networks() const {
    return m_networks;
}

bool NetworkManagerProvider::scanning() const {
    return m_scanning;
}

void NetworkManagerProvider::updateWifiStatus() {
    bool enabled = NetworkManager::isWirelessEnabled();
    if (m_wifiEnabled != enabled) {
        m_wifiEnabled = enabled;
        emit wifiEnabledChanged();
    }
}

void NetworkManagerProvider::updateConnectionStatus() {
    bool connected = false;
    QString activeName;
    
    for (const auto& ac : NetworkManager::activeConnections()) {
        if (ac->state() == NetworkManager::ActiveConnection::Activated) {
            connected = true;
            activeName = ac->id();
            break;
        }
    }
    
    if (m_isConnected != connected) {
        m_isConnected = connected;
        emit isConnectedChanged();
    }
    
    if (m_activeConnection != activeName) {
        m_activeConnection = activeName;
        emit activeConnectionChanged();
    }
    
    updateNetworks();
}

void NetworkManagerProvider::handleDeviceAdded(const QString& udi) {
    NetworkManager::Device::Ptr dev = NetworkManager::findNetworkInterface(udi);
    if (dev && dev->type() == NetworkManager::Device::Wifi) {
        NetworkManager::WirelessDevice::Ptr wifiDev = qSharedPointerCast<NetworkManager::WirelessDevice>(dev);
        connect(wifiDev.data(), &NetworkManager::WirelessDevice::networkAppeared, this, &NetworkManagerProvider::updateNetworks);
        connect(wifiDev.data(), &NetworkManager::WirelessDevice::networkDisappeared, this, &NetworkManagerProvider::updateNetworks);
        connect(wifiDev.data(), &NetworkManager::WirelessDevice::stateChanged, this, &NetworkManagerProvider::updateNetworks);
        updateNetworks();
    }
}

void NetworkManagerProvider::handleDeviceRemoved(const QString& /*udi*/) {
    updateNetworks();
}

NetworkManager::WirelessDevice::Ptr NetworkManagerProvider::getWirelessDevice() const {
    for (const auto& dev : NetworkManager::networkInterfaces()) {
        if (dev->type() == NetworkManager::Device::Wifi) {
            return qSharedPointerCast<NetworkManager::WirelessDevice>(dev);
        }
    }
    return nullptr;
}

void NetworkManagerProvider::updateNetworks() {
    auto wifiDev = getWirelessDevice();
    if (!wifiDev) {
        if (!m_networks.isEmpty()) {
            m_networks.clear();
            emit networksChanged();
        }
        return;
    }

    QVariantList newNetworks;
    auto networks = wifiDev->networks();
    auto activeAp = wifiDev->activeAccessPoint();
    
    for (const auto& net : networks) {
        auto aps = net->accessPoints();
        if (aps.isEmpty()) continue;
        
        // Find best access point for this network
        NetworkManager::AccessPoint::Ptr bestAp = aps.first();
        bool isActive = false;
        
        for (const auto& ap : aps) {
            if (activeAp && ap->uni() == activeAp->uni()) {
                isActive = true;
                bestAp = ap;
                break;
            } else if (ap->signalStrength() > bestAp->signalStrength()) {
                bestAp = ap;
            }
        }
        
        newNetworks.append(serializeAccessPoint(bestAp, isActive));
    }
    
    // Simple deduplication/reordering based on signal / active state
    std::sort(newNetworks.begin(), newNetworks.end(), [](const QVariant& a, const QVariant& b) {
        auto mapA = a.toMap();
        auto mapB = b.toMap();
        if (mapA["active"].toBool() != mapB["active"].toBool()) {
            return mapA["active"].toBool();
        }
        return mapA["strength"].toInt() > mapB["strength"].toInt();
    });

    m_networks = newNetworks;
    emit networksChanged();
}

QVariantMap NetworkManagerProvider::serializeAccessPoint(const NetworkManager::AccessPoint::Ptr& ap, bool isActive) const {
    QVariantMap map;
    map["ssid"] = ap->ssid();
    map["bssid"] = ap->hardwareAddress();
    map["strength"] = ap->signalStrength();
    map["frequency"] = ap->frequency();
    map["active"] = isActive;
    
    QString security;
    auto flags = ap->wpaFlags() | ap->rsnFlags();
    if (flags & NetworkManager::AccessPoint::KeyMgmtPsk) security = "WPA2";
    else if (flags & NetworkManager::AccessPoint::KeyMgmt8021x) security = "802.1X";
    else if (ap->capabilities() & NetworkManager::AccessPoint::Privacy) security = "WEP";
    map["security"] = security;
    
    return map;
}

void NetworkManagerProvider::rescanWifi() {
    auto dev = getWirelessDevice();
    if (dev) {
        dev->requestScan();
        m_scanning = true;
        emit scanningChanged();
        QTimer::singleShot(5000, this, [this]() {
            m_scanning = false;
            emit scanningChanged();
        });
    }
}

void NetworkManagerProvider::toggleWifi() {
    NetworkManager::setWirelessEnabled(!NetworkManager::isWirelessEnabled());
}

void NetworkManagerProvider::connectToNetwork(const QString& ssid) {
    auto dev = getWirelessDevice();
    if (!dev) return;

    // Check if preferred connection already exists
    for (const auto& conn : NetworkManager::listConnections()) {
        auto settings = conn->settings();
        auto wireless = qSharedPointerDynamicCast<NetworkManager::WirelessSetting>(settings->setting(NetworkManager::Setting::Wireless));
        if (wireless && QString::fromUtf8(wireless->ssid()) == ssid) {
            NetworkManager::activateConnection(conn->path(), dev->uni(), QString());
            return;
        }
    }
}

void NetworkManagerProvider::connectToSecureNetwork(const QString& ssid, const QString& password) {
    auto dev = getWirelessDevice();
    if (!dev) return;

    NetworkManager::ConnectionSettings::Ptr settings = NetworkManager::ConnectionSettings::Ptr(new NetworkManager::ConnectionSettings(NetworkManager::ConnectionSettings::Wireless));
    settings->setId(ssid);
    settings->setUuid(NetworkManager::ConnectionSettings::createNewUuid());
    settings->setAutoconnect(true);

    auto wireless = qSharedPointerDynamicCast<NetworkManager::WirelessSetting>(settings->setting(NetworkManager::Setting::Wireless));
    wireless->setSsid(ssid.toUtf8());

    auto security = qSharedPointerDynamicCast<NetworkManager::WirelessSecuritySetting>(settings->setting(NetworkManager::Setting::WirelessSecurity));
    security->setKeyMgmt(NetworkManager::WirelessSecuritySetting::WpaPsk);
    security->setPsk(password);
    
    auto ipv4 = qSharedPointerDynamicCast<NetworkManager::Ipv4Setting>(settings->setting(NetworkManager::Setting::Ipv4));
    ipv4->setMethod(NetworkManager::Ipv4Setting::Automatic);
    
    auto ipv6 = qSharedPointerDynamicCast<NetworkManager::Ipv6Setting>(settings->setting(NetworkManager::Setting::Ipv6));
    ipv6->setMethod(NetworkManager::Ipv6Setting::Automatic);

    NetworkManager::addAndActivateConnection(settings->toMap(), dev->uni(), QString());
}

void NetworkManagerProvider::disconnectFromNetwork() {
    auto dev = getWirelessDevice();
    if (dev) {
        dev->disconnectInterface();
    }
}

void NetworkManagerProvider::deleteNetwork(const QString& ssid) {
    for (const auto& conn : NetworkManager::listConnections()) {
        auto settings = conn->settings();
        auto wireless = qSharedPointerDynamicCast<NetworkManager::WirelessSetting>(settings->setting(NetworkManager::Setting::Wireless));
        if (wireless && QString::fromUtf8(wireless->ssid()) == ssid) {
            conn->remove();
            break;
        }
    }
}
