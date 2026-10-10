import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Settings.Components

AppContainer {
    id: root

    property var availableCursors: []

    Process {
        id: fetchCursorsProc

        command: ["sh", "-c", "find /usr/share/icons ~/.local/share/icons ~/.icons -type d -name 'cursors' 2>/dev/null | awk -F'/' '{print $(NF-1)}' | sort -u"]
        Component.onCompleted: running = true

        stdout: SplitParser {
            onRead: (data) => {
                if (data) {
                    let lines = data.split('\n').map((x) => {
                        return x.trim();
                    }).filter((x) => {
                        return x !== "";
                    });
                    let arr = root.availableCursors.slice();
                    let changed = false;
                    lines.forEach((l) => {
                        if (arr.indexOf(l) === -1) {
                            arr.push(l);
                            changed = true;
                        }
                    });
                    if (arr.indexOf(SettingsService.cursorTheme) === -1 && SettingsService.cursorTheme) {
                        arr.unshift(SettingsService.cursorTheme);
                        changed = true;
                    }
                    if (changed)
                        root.availableCursors = arr;

                }
            }
        }

    }

    AppGroup {
        title: "Pointer & DPI"
        icon: "cursor"

        SettingSpinBox {
            label: "Pointer Sensitivity (DPI Speed)"
            description: "Relative speed of the mouse pointer (-1.0 slow to 1.0 fast)"
            from: -1
            to: 1
            stepSize: 0.05
            value: HyprlandService.mouseSensitivity
            defaultValue: 0
            decimals: 2
            onMoved: (val) => {
                HyprlandService.mouseSensitivity = Number(val.toFixed(2));
            }
        }

        SettingSegmented {
            label: "Acceleration Profile"
            description: "Flat disables acceleration for consistent 1:1 hardware tracking"
            model: [{
                "text": "Flat (Raw 1:1)",
                "value": "flat"
            }, {
                "text": "Adaptive",
                "value": "adaptive"
            }]
            currentValue: HyprlandService.mouseAccelProfile === "flat" ? "flat" : "adaptive"
            onActivated: (val) => {
                HyprlandService.mouseAccelProfile = val;
            }
        }

        SettingToggle {
            id: leftHandedToggle

            label: "Left-Handed Mouse"
            description: "Swap primary left and right click buttons"
            checked: HyprlandService.mouseLeftHanded
            onCheckedChanged: {
                if (checked !== HyprlandService.mouseLeftHanded)
                    HyprlandService.mouseLeftHanded = checked;

            }

            Binding {
                target: leftHandedToggle
                property: "checked"
                value: HyprlandService.mouseLeftHanded
            }

        }

    }

    AppGroup {
        title: "Scrolling & Navigation"
        icon: "reload"

        SettingToggle {
            id: naturalScrollToggle

            label: "Natural Scrolling"
            description: "Invert scroll wheel direction"
            checked: HyprlandService.mouseNaturalScroll
            onCheckedChanged: {
                if (checked !== HyprlandService.mouseNaturalScroll)
                    HyprlandService.mouseNaturalScroll = checked;

            }

            Binding {
                target: naturalScrollToggle
                property: "checked"
                value: HyprlandService.mouseNaturalScroll
            }

        }

        SettingSpinBox {
            label: "Scroll Speed Factor"
            description: "Multiplier for mouse scroll wheel velocity"
            from: 0.2
            to: 3
            stepSize: 0.1
            defaultValue: 1
            suffix: "x"
            decimals: 1
            value: HyprlandService.mouseScrollFactor
            onMoved: (val) => {
                HyprlandService.mouseScrollFactor = Number(val.toFixed(1));
            }
        }

    }

    AppGroup {
        title: "Cursor & Focus"
        icon: "cursor"

        ThemedSelect {
            id: cursorSelect

            function updateSelection() {
                for (let i = 0; i < root.availableCursors.length; i++) {
                    if (root.availableCursors[i] === SettingsService.cursorTheme) {
                        cursorSelect.currentIndex = i;
                        return ;
                    }
                }
            }

            label: "Cursor Theme"
            description: "System-wide mouse pointer theme"
            comboWidth: 260
            searchable: true
            model: root.availableCursors
            Component.onCompleted: updateSelection()
            onModelChanged: updateSelection()
            onActivated: (index) => {
                let newTheme = model[index];
                if (SettingsService.cursorTheme !== newTheme)
                    SettingsService.cursorTheme = newTheme;

            }

            Connections {
                function onCursorThemeChanged() {
                    cursorSelect.updateSelection();
                }

                target: SettingsService
            }

        }

        SettingSegmented {
            label: "Cursor Size"
            description: "Size of the mouse cursor in pixels"
            model: [{
                "text": "24",
                "value": 24
            }, {
                "text": "32",
                "value": 32
            }, {
                "text": "48",
                "value": 48
            }, {
                "text": "64",
                "value": 64
            }]
            currentValue: SettingsService.cursorSize
            onActivated: (value) => {
                SettingsService.cursorSize = value;
            }
        }

        SettingSpinBox {
            label: "Hide Cursor Timeout"
            description: "Seconds before idle cursor disappears (0 to keep visible)"
            from: 0
            to: 60
            stepSize: 1
            decimals: 0
            allowOff: true
            offText: "Never"
            suffix: "s"
            value: HyprlandService.cursorInactiveTimeout
            defaultValue: 5
            onMoved: (val) => {
                HyprlandService.cursorInactiveTimeout = Math.round(val);
            }
        }

        SettingSegmented {
            label: "Window Focus Behavior"
            description: "Whether window focus follows cursor movement or requires click"
            model: [{
                "text": "Follow Mouse",
                "value": 1
            }, {
                "text": "Click to Focus",
                "value": 0
            }]
            currentValue: HyprlandService.mouseFollowMouse
            onActivated: (val) => {
                HyprlandService.mouseFollowMouse = val;
            }
        }

    }

    AppGroup {
        title: "Touchpad"
        icon: "touchpad"

        SettingToggle {
            id: tapToClickToggle

            label: "Tap to Click"
            description: "Tap the surface with one finger to click"
            checked: HyprlandService.touchpadTapToClick
            onCheckedChanged: {
                if (checked !== HyprlandService.touchpadTapToClick)
                    HyprlandService.touchpadTapToClick = checked;

            }

            Binding {
                target: tapToClickToggle
                property: "checked"
                value: HyprlandService.touchpadTapToClick
            }

        }

        SettingToggle {
            id: touchpadNaturalScrollToggle

            label: "Touchpad Natural Scroll"
            description: "Two-finger scrolling moves content in finger direction"
            checked: HyprlandService.touchpadNaturalScroll
            onCheckedChanged: {
                if (checked !== HyprlandService.touchpadNaturalScroll)
                    HyprlandService.touchpadNaturalScroll = checked;

            }

            Binding {
                target: touchpadNaturalScrollToggle
                property: "checked"
                value: HyprlandService.touchpadNaturalScroll
            }

        }

        SettingToggle {
            id: disableWhileTypingToggle

            label: "Disable While Typing"
            description: "Prevent accidental touchpad clicks while typing on keyboard"
            checked: HyprlandService.touchpadDisableWhileTyping
            onCheckedChanged: {
                if (checked !== HyprlandService.touchpadDisableWhileTyping)
                    HyprlandService.touchpadDisableWhileTyping = checked;

            }

            Binding {
                target: disableWhileTypingToggle
                property: "checked"
                value: HyprlandService.touchpadDisableWhileTyping
            }

        }

    }

}
