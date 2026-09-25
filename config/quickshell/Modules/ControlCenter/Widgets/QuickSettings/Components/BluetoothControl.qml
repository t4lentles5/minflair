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
    property var btList: []
    property bool isVisible: true

    function toggle() {
        btSetProc.command = ["python3", Quickshell.shellDir + "/Scripts/bluetooth.py", "toggle-power"];
        btSetProc.running = true;
    }

    function scan() {
        if (root.expanded && root.isActive) {
            if (!btDiscoveryProc.running)
                btDiscoveryProc.running = true;

        }
    }

    function connect(mac) {
        btConnectProc.command = ["python3", Quickshell.shellDir + "/Scripts/bluetooth.py", "toggle-connect", mac];
        btConnectProc.running = true;
    }

    icon: root.isActive ? "bluetooth" : "bluetooth-off"
    label: "Bluetooth"
    subtitle: {
        if (!isActive)
            return "Off";

        for (let i = 0; i < btList.length; i++) {
            if (btList[i].connected)
                return btList[i].name;

        }
        return "Disconnected";
    }
    onClicked: root.toggle()
    onExpandedChanged: {
        if (expanded && isActive) {
            if (!btDiscoveryProc.running)
                btDiscoveryProc.running = true;

        } else {
            btDiscoveryProc.running = false;
        }
    }
    onIsActiveChanged: {
        if (expanded && isActive) {
            if (!btDiscoveryProc.running)
                btDiscoveryProc.running = true;

        } else {
            btDiscoveryProc.running = false;
        }
        if (!isActive)
            expanded = false;

    }

    Timer {
        id: updateTimer

        interval: 2500
        running: root.isVisible
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            btGetProc.running = true;
        }
    }

    Process {
        id: btGetProc

        command: ["python3", Quickshell.shellDir + "/Scripts/bluetooth.py", "status"]

        stdout: SplitParser {
            onRead: (data) => {
                if (!data)
                    return ;

                try {
                    let parsed = JSON.parse(data);
                    root.isActive = parsed.powered;
                    if (!root.expanded)
                        root.btList = parsed.devices || [];

                } catch (e) {
                }
            }
        }

    }

    Process {
        id: btSetProc

        onRunningChanged: {
            if (!running)
                btGetProc.running = true;

        }
    }

    Process {
        id: btDiscoveryProc

        command: ["python3", Quickshell.shellDir + "/Scripts/bluetooth.py", "scan"]

        stdout: SplitParser {
            onRead: (data) => {
                if (!data)
                    return ;

                try {
                    let parsed = JSON.parse(data);
                    if (parsed.event === "devices")
                        root.btList = parsed.devices || [];

                } catch (e) {
                }
            }
        }

    }

    Process {
        id: btConnectProc

        onRunningChanged: {
            if (!running)
                btGetProc.running = true;

        }
    }

}
