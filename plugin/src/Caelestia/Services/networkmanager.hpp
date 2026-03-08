#pragma once

#include <QObject>
#include <QVariantList>
#include <QString>
#include <QTimer>
#include <QtQml/qqml.h>

#include <NetworkManagerQt/Manager>
#include <NetworkManagerQt/WirelessDevice>
#include <NetworkManagerQt/AccessPoint>

class NetworkManagerProvider : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(bool wifiEnabled READ wifiEnabled WRITE setWifiEnabled NOTIFY wifiEnabledChanged)
    Q_PROPERTY(bool isConnected READ isConnected NOTIFY isConnectedChanged)
    Q_PROPERTY(QString activeConnection READ activeConnection NOTIFY activeConnectionChanged)
    Q_PROPERTY(QVariantList networks READ networks NOTIFY networksChanged)
    Q_PROPERTY(bool scanning READ scanning NOTIFY scanningChanged)

public:
    explicit NetworkManagerProvider(QObject* parent = nullptr);
    ~NetworkManagerProvider() override = default;

    bool wifiEnabled() const;
    void setWifiEnabled(bool enabled);

    bool isConnected() const;
    QString activeConnection() const;
    QVariantList networks() const;
    bool scanning() const;

    Q_INVOKABLE void connectToNetwork(const QString& ssid);
    Q_INVOKABLE void connectToSecureNetwork(const QString& ssid, const QString& password);
    Q_INVOKABLE void disconnectFromNetwork();
    Q_INVOKABLE void deleteNetwork(const QString& ssid);
    Q_INVOKABLE void toggleWifi();
    Q_INVOKABLE void rescanWifi();

signals:
    void wifiEnabledChanged();
    void isConnectedChanged();
    void activeConnectionChanged();
    void networksChanged();
    void scanningChanged();
    void connectionFailed(const QString& ssid);

private slots:
    void updateWifiStatus();
    void updateConnectionStatus();
    void updateNetworks();
    void handleDeviceAdded(const QString& udi);
    void handleDeviceRemoved(const QString& udi);

private:
    NetworkManager::WirelessDevice::Ptr getWirelessDevice() const;
    QVariantMap serializeAccessPoint(const NetworkManager::AccessPoint::Ptr& ap, bool isActive) const;

    bool m_wifiEnabled = false;
    bool m_isConnected = false;
    QString m_activeConnection;
    QVariantList m_networks;
    bool m_scanning = false;
    
    QTimer m_scanTimer;
};
