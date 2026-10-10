import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Core
import qs.Core.Components

QuickSettingsTile {
    id: root

    property bool expanded: false
    property bool isScanning: wifiScanProc.running
    property var wifiList: []
    property string connectedSsid: "Disconnected"
    property string currentSsid: {
        if (!isActive)
            return "Off";

        return connectedSsid;
    }
    property bool isVisible: true

    function toggle() {
        wifiSetProc.command = ["python3", Quickshell.shellDir + "/Modules/ControlCenter/scripts/wifi.py", "toggle-radio"];
        wifiSetProc.running = true;
        root.isActive = !root.isActive;
    }

    function scan(forceRescan) {
        if (!root.isActive)
            return ;

        let rescan = (forceRescan === undefined) ? true : forceRescan;
        wifiScanProc.command = ["python3", Quickshell.shellDir + "/Modules/ControlCenter/scripts/wifi.py", "scan", rescan ? "yes" : "no"];
        wifiScanProc.running = false;
        wifiScanProc.running = true;
    }

    function connect(ssid) {
        wifiConnectProc.command = ["python3", Quickshell.shellDir + "/Modules/ControlCenter/scripts/wifi.py", "connect", ssid];
        wifiConnectProc.running = true;
    }

    hasMenu: true
    icon: root.isActive ? "wifi" : "wifi-off"
    label: "Wi-Fi"
    subtitle: root.currentSsid
    onClicked: root.toggle()
    onExpandedChanged: {
        if (expanded)
            scan(true);

    }
    onIsActiveChanged: {
        if (isActive) {
            scan(false);
            if (expanded)
                scan(true);

        } else {
            wifiList = [];
            connectedSsid = "Disconnected";
        }
    }
    onIsVisibleChanged: {
        if (isVisible && isActive && root.wifiList.length === 0)
            scan(false);

    }
    Component.onCompleted: {
        if (isActive && root.wifiList.length === 0)
            scan(false);

    }

    Timer {
        interval: 2000
        running: root.isVisible
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            wifiGetProc.running = true;
        }
    }

    Process {
        id: wifiGetProc

        command: ["python3", Quickshell.shellDir + "/Modules/ControlCenter/scripts/wifi.py", "status"]

        stdout: SplitParser {
            onRead: (data) => {
                if (!data)
                    return ;

                try {
                    let st = JSON.parse(data.trim());
                    root.isActive = st.radio;
                    root.connectedSsid = st.connected_ssid || "Disconnected";
                } catch (e) {
                }
            }
        }

    }

    Process {
        id: wifiSetProc

        onRunningChanged: {
            if (!running)
                wifiGetProc.running = true;

        }
    }

    Process {
        id: wifiScanProc

        command: ["python3", Quickshell.shellDir + "/Modules/ControlCenter/scripts/wifi.py", "scan"]

        stdout: SplitParser {
            onRead: (data) => {
                if (!data)
                    return ;

                try {
                    let list = JSON.parse(data.trim());
                    if (Array.isArray(list))
                        root.wifiList = list;

                } catch (e) {
                }
            }
        }

    }

    Process {
        id: wifiConnectProc

        onRunningChanged: {
            if (!running) {
                wifiGetProc.running = true;
                root.scan(true);
            }
        }
    }

}
