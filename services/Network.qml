pragma Singleton

import Quickshell
import QtQuick
import Caelestia.Services

Singleton {
    id: root

    property bool wifiEnabled: NetworkManagerProvider.wifiEnabled
    readonly property bool scanning: NetworkManagerProvider.scanning
    property bool isconnectionFailed: false
    property string _currentssid: ""

    readonly property list<AccessPoint> networks: {
        let list = []
        for (let i = 0; i < NetworkManagerProvider.networks.length; i++) {
            list.push(apComp.createObject(root, { lastIpcObject: NetworkManagerProvider.networks[i] }))
        }
        return list
    }
    
    readonly property AccessPoint active: networks.find(n => n.active) ?? null

    function enableWifi(enabled: bool): void {
        NetworkManagerProvider.wifiEnabled = enabled;
    }

    function toggleWifi(): void {
        NetworkManagerProvider.toggleWifi();
    }

    function rescanWifi(): void {
        NetworkManagerProvider.rescanWifi();
    }

    function connectToNetwork(ssid: string): void {
        isconnectionFailed = false;
        _currentssid = ssid;
        NetworkManagerProvider.connectToNetwork(ssid);
    }

    function connectToSecureNetwork(ssid: string, password: string): void {
        isconnectionFailed = false;
        _currentssid = ssid;
        NetworkManagerProvider.connectToSecureNetwork(ssid, password);
    }

    function deleteNetwork(ssid: string): void {
        NetworkManagerProvider.deleteNetwork(ssid);
    }

    function disconnectFromNetwork(): void {
        NetworkManagerProvider.disconnectFromNetwork();
    }

    function getWifiStatus(): void {
        // Now automatic Property from provider
    }

    Connections {
        target: NetworkManagerProvider
        function onConnectionFailed(ssid) {
            root.isconnectionFailed = true;
            root.deleteNetwork(ssid);
        }
    }

    component AccessPoint: QtObject {
        required property var lastIpcObject
        readonly property string ssid: lastIpcObject.ssid
        readonly property string bssid: lastIpcObject.bssid
        readonly property int strength: lastIpcObject.strength
        readonly property int frequency: lastIpcObject.frequency
        readonly property bool active: lastIpcObject.active
        readonly property string security: lastIpcObject.security
        readonly property bool isSecure: security !== ""
    }

    Component {
        id: apComp
        AccessPoint {}
    }
}
