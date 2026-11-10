import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Settings.Components

AppContainer {
    id: windowRoot

    property var monitors: []

    function refreshMonitors() {
        if (!monitorsProc.running)
            monitorsProc.running = true;

    }

    function monitorModeLabel(mode) {
        let clean = mode.replace("Hz", "");
        let parts = clean.split("@");
        let resolution = parts[0].split("x").join(" × ");
        if (parts.length < 2)
            return resolution;

        let refresh = parseFloat(parts[1]);
        return resolution + " · " + (isNaN(refresh) ? parts[1] : Math.round(refresh) + " Hz");
    }

    function parseMonitors(text) {
        try {
            let list = JSON.parse(text);
            if (!Array.isArray(list))
                return ;

            let parsed = [];
            for (let i = 0; i < list.length; i++) {
                let monitor = list[i];
                if (monitor.disabled)
                    continue;

                let rawModes = monitor.availableModes || [];
                let currentWidth = monitor.width + "x" + monitor.height;
                let currentIndex = 0;
                for (let j = 0; j < rawModes.length; j++) {
                    let parts = rawModes[j].replace("Hz", "").split("@");
                    if (parts[0] !== currentWidth)
                        continue;

                    if (parts.length < 2 || Math.abs(parseFloat(parts[1]) - monitor.refreshRate) < 0.5) {
                        currentIndex = j;
                        break;
                    }
                }
                parsed.push({
                    "name": monitor.name,
                    "description": monitor.description || "",
                    "rawModes": rawModes,
                    "modes": rawModes.map(windowRoot.monitorModeLabel),
                    "currentIndex": currentIndex
                });
            }
            windowRoot.monitors = parsed;
        } catch (e) {
            console.error("Could not parse hyprctl monitors: " + e);
        }
    }

    Component.onCompleted: refreshMonitors()

    AppGroup {
        title: "Monitors"
        icon: "monitor"

        ThemedText {
            visible: windowRoot.monitors.length === 0
            text: "No active monitors detected."
            customSize: Constants.sizeXs + 3
            color: Theme.muted
        }

        Repeater {
            model: windowRoot.monitors

            delegate: ThemedSelect {
                label: modelData.name
                description: modelData.description !== "" ? modelData.description : "Resolution and refresh rate"
                comboWidth: 260
                model: modelData.modes
                currentIndex: modelData.currentIndex
                onActivated: (index) => {
                    let mode = modelData.rawModes[index];
                    monitorApplyProc.command = ["python3", Quickshell.shellDir + "/Scripts/system/hypr_monitors.py", "set-mode", modelData.name, mode];
                    monitorApplyProc.running = false;
                    monitorApplyProc.running = true;
                }
            }

        }

    }

    AppGroup {
        title: "Display Scaling"
        icon: "monitor"

        SettingSegmented {
            label: "Hyprland Monitor Scale"
            description: "Global Wayland display scaling"
            model: [{
                "text": "100%",
                "value": 1
            }, {
                "text": "125%",
                "value": 1.25
            }, {
                "text": "150%",
                "value": 1.5
            }, {
                "text": "200%",
                "value": 2
            }]
            currentValue: SettingsService.hyprScale
            onActivated: (value) => {
                SettingsService.hyprScale = value;
                hyprScaleApplyProc.running = false;
                hyprScaleApplyProc.running = true;
            }

            Process {
                id: hyprScaleApplyProc

                command: ["sh", "-c", "\"$1\" \"$2\"", "minflair-hypr-scale", Quickshell.shellDir + "/Scripts/system/hypr_scale.sh", "" + SettingsService.hyprScale]
            }

        }

    }

    AppGroup {
        title: "Window Geometry & Tiling"
        icon: "window"

        SettingSpinBox {
            label: "Window Rounding"
            from: 0
            to: 40
            stepSize: 1
            value: HyprlandService.hyprRounding
            defaultValue: 32
            suffix: "px"
            onMoved: (val) => {
                HyprlandService.hyprRounding = Math.round(val);
            }
        }

        SettingSpinBox {
            label: "Gaps In"
            description: "Modifying this may break the Convex Style layout"
            from: 0
            to: 20
            stepSize: 1
            value: HyprlandService.hyprGapsIn
            defaultValue: 4
            suffix: "px"
            onMoved: (val) => {
                HyprlandService.hyprGapsIn = Math.round(val);
            }
        }

        SettingSpinBox {
            label: "Gaps Out"
            description: "Modifying this may break the Convex Style layout"
            from: 0
            to: 40
            stepSize: 1
            value: HyprlandService.hyprGapsOut
            defaultValue: Constants.sizeXs
            suffix: "px"
            onMoved: (val) => {
                HyprlandService.hyprGapsOut = Math.round(val);
            }
        }

        SettingSpinBox {
            label: "Border Size"
            from: 0
            to: 10
            stepSize: 1
            value: HyprlandService.hyprBorderSize
            defaultValue: 2
            suffix: "px"
            onMoved: (val) => {
                HyprlandService.hyprBorderSize = Math.round(val);
            }
        }

    }

    Process {
        id: monitorsProc

        command: ["hyprctl", "monitors", "-j"]
        onExited: (code) => {
            if (code === 0)
                windowRoot.parseMonitors(monitorsStdout.text);

        }

        stdout: StdioCollector {
            id: monitorsStdout
        }

    }

    Process {
        id: monitorApplyProc

        onExited: (code) => {
            if (code === 0)
                windowRoot.refreshMonitors();

        }
    }

}
