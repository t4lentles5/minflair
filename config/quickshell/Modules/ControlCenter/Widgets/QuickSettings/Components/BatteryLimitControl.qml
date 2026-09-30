import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Core
import qs.Core.Components
import qs.Core.Services

QuickSettingsTile {
    id: root

    property bool isLimitActive: false
    property bool isVisible: true
    property bool disabled: false

    isActive: root.isLimitActive
    icon: isActive ? "charger-filled" : "charger"
    label: "Battery Limit"
    subtitle: root.disabled ? "Unsupported" : (root.isLimitActive ? "80% Limit" : "100%")
    onMenuClicked: clicked()
    onClicked: {
        toggleProcess.running = true;
    }

    Timer {
        id: updateTimer

        interval: 5000
        running: root.isVisible
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            statusProcess.running = true;
        }
    }

    Process {
        id: statusProcess

        command: [Quickshell.shellDir + "/Scripts/system/toggle_battery_limit.sh", "status"]

        stdout: SplitParser {
            onRead: (data) => {
                if (!data)
                    return ;

                let val = data.trim();
                root.visible = true;
                if (val === "1") {
                    root.isLimitActive = true;
                    root.disabled = false;
                    root.opacity = 1;
                } else if (val === "0") {
                    root.isLimitActive = false;
                    root.disabled = false;
                    root.opacity = 1;
                } else if (val === "unsupported") {
                    root.disabled = true;
                    root.isLimitActive = false;
                    root.opacity = 0.4;
                }
            }
        }

    }

    Process {
        id: toggleProcess

        command: ["sudo", Quickshell.shellDir + "/Scripts/system/toggle_battery_limit.sh", "toggle"]
        onRunningChanged: {
            if (!running)
                statusProcess.running = true;

        }

        stdout: SplitParser {
            onRead: (data) => {
                if (data && data.trim() === "1")
                    root.isLimitActive = true;
                else if (data && data.trim() === "0")
                    root.isLimitActive = false;
            }
        }

    }

}
