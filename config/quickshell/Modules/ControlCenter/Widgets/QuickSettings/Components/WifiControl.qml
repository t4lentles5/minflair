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
    property var wifiList: []
    property var _tempWifiList: []
    property string connectedSsid: "Disconnected"
    property string currentSsid: {
        if (!isActive)
            return "Off";

        return connectedSsid;
    }
    property bool isVisible: true

    function toggle() {
        wifiSetProc.command = ["nmcli", "radio", "wifi", root.isActive ? "off" : "on"];
        wifiSetProc.running = true;
        root.isActive = !root.isActive;
    }

    function scan() {
        if (root.expanded)
            wifiScanProc.running = true;

    }

    function connect(ssid) {
        wifiConnectProc.command = ["nmcli", "device", "wifi", "connect", ssid];
        wifiConnectProc.running = true;
    }

    icon: root.isActive ? "wifi" : "wifi-off"
    label: "Wi-Fi"
    subtitle: root.currentSsid
    onClicked: root.toggle()

    Timer {
        interval: 2000
        running: root.isVisible
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            wifiGetProc.running = true;
            if (root.expanded)
                scan();

        }
    }

    Process {
        id: wifiGetProc

        command: ["sh", "-c", "echo \"radio:$(nmcli radio wifi)\"; nmcli -t -f TYPE,STATE,CONNECTION device | grep \"^wifi:\""]

        stdout: SplitParser {
            onRead: (data) => {
                if (!data)
                    return ;

                let line = data.trim();
                if (line.startsWith("radio:")) {
                    let status = line.substring(6);
                    root.isActive = (status === "enabled");
                } else if (line.startsWith("wifi:")) {
                    let parts = line.split(":");
                    if (parts.length >= 3 && parts[1] === "connected")
                        root.connectedSsid = parts[2];
                    else
                        root.connectedSsid = "Disconnected";
                }
            }
        }

    }

    Process {
        id: wifiSetProc
    }

    Process {
        id: wifiScanProc

        command: ["nmcli", "-t", "-f", "SSID,SIGNAL,IN-USE,SECURITY", "device", "wifi", "list"]
        onRunningChanged: {
            if (running)
                root._tempWifiList = [];
            else
                root.wifiList = root._tempWifiList;
        }

        stdout: SplitParser {
            onRead: (data) => {
                if (!data)
                    return ;

                let cleanLine = data.trim().replace(/\\:/g, "__COLON__");
                let parts = cleanLine.split(":");
                if (parts.length < 4)
                    return ;

                let ssid = parts[0].replace(/__COLON__/g, ":");
                let signal = parseInt(parts[1]);
                let inUse = parts[2] === "*";
                let security = parts[3].replace(/__COLON__/g, ":");
                if (!ssid)
                    return ;

                let list = root._tempWifiList;
                let exists = false;
                for (let i = 0; i < list.length; i++) {
                    if (list[i].ssid === ssid) {
                        exists = true;
                        if (inUse || signal > list[i].signal) {
                            list[i].signal = signal;
                            list[i].active = inUse;
                            list[i].secured = security && security !== "--" && security !== "";
                        }
                        break;
                    }
                }
                if (!exists)
                    list.push({
                    "ssid": ssid,
                    "signal": signal,
                    "active": inUse,
                    "secured": security && security !== "--" && security !== ""
                });

                root._tempWifiList = list;
            }
        }

    }

    Process {
        id: wifiConnectProc
    }

}
