import "Components"
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
    id: wallpaperRoot

    AppGroup {
        title: "Screen Framing & Cropping"
        icon: "picture-spark"
        showDividers: false

        WallpaperCropPreview {
            Layout.fillWidth: true
        }

        SettingSegmented {
            label: "Scaling Mode"
            description: "How wallpapers adapt across different aspect ratios"
            model: [{
                "text": "Crop (Fill)",
                "value": "crop"
            }, {
                "text": "Fit",
                "value": "fit"
            }, {
                "text": "Stretch",
                "value": "stretch"
            }]
            currentValue: HyprlandService.wpResizeMode
            onActivated: (val) => {
                HyprlandService.wpResizeMode = val;
            }
        }

    }

    AppGroup {
        title: "Automation & Transitions"
        icon: "sparkles"

        SettingToggle {
            id: autoShuffleToggle

            label: "Auto-shuffle Wallpapers"
            onCheckedChanged: {
                if (checked !== HyprlandService.wpAutoShuffle)
                    HyprlandService.wpAutoShuffle = checked;

            }

            Binding {
                target: autoShuffleToggle
                property: "checked"
                value: HyprlandService.wpAutoShuffle
            }

        }

        SettingSpinBox {
            enabled: HyprlandService.wpAutoShuffle
            opacity: enabled ? 1 : 0.5
            label: "Shuffle Interval"
            from: 1
            to: 60
            stepSize: 1
            value: HyprlandService.wpShuffleInterval
            suffix: " min"
            decimals: 0
            onMoved: (val) => {
                HyprlandService.wpShuffleInterval = Math.round(val);
            }
        }

        ThemedSelect {
            label: "Transition Type"
            model: ["none", "grow", "fade", "wipe", "wave", "random"]
            currentIndex: {
                if (!HyprlandService.wpEnableTransitions)
                    return 0;

                let idx = model.indexOf(HyprlandService.wpTransitionType);
                return idx !== -1 ? idx : 1;
            }
            onActivated: (index) => {
                let val = model[index];
                if (val === "none") {
                    HyprlandService.wpEnableTransitions = false;
                } else {
                    HyprlandService.wpEnableTransitions = true;
                    HyprlandService.wpTransitionType = val;
                }
            }
        }

        ThemedSelect {
            label: "Transition Position"
            model: ["top-left", "top", "top-right", "left", "center", "right", "bottom-left", "bottom", "bottom-right"]
            currentIndex: {
                let idx = model.indexOf(HyprlandService.wpTransitionPos);
                return idx !== -1 ? idx : 4;
            }
            onActivated: (index) => {
                HyprlandService.wpTransitionPos = model[index];
            }
            enabled: HyprlandService.wpEnableTransitions && HyprlandService.wpTransitionType !== "random"
            opacity: enabled ? 1 : 0.4

            Behavior on opacity {
                NumberAnimation {
                    duration: Constants.animFast
                }

            }

        }

        ColumnLayout {
            spacing: Constants.sizeLg
            Layout.fillWidth: true
            enabled: HyprlandService.wpEnableTransitions
            opacity: enabled ? 1 : 0.4

            SettingSegmented {
                label: "Transition Speed"
                model: [{
                    "text": "Slow",
                    "value": 60
                }, {
                    "text": "Normal",
                    "value": 120
                }, {
                    "text": "Fast",
                    "value": 180
                }, {
                    "text": "Ultra",
                    "value": 240
                }]
                currentValue: HyprlandService.wpTransitionStep
                onActivated: (val) => {
                    HyprlandService.wpTransitionStep = val;
                }
            }

            Divider {
            }

            SettingSegmented {
                label: "Transition Frame Rate"
                model: [{
                    "text": "30",
                    "value": 30
                }, {
                    "text": "60",
                    "value": 60
                }, {
                    "text": "120",
                    "value": 120
                }, {
                    "text": "144",
                    "value": 144
                }]
                currentValue: HyprlandService.wpTransitionFps
                onActivated: (val) => {
                    HyprlandService.wpTransitionFps = val;
                }
            }

            Divider {
                visible: HyprlandService.wpTransitionType === "wipe" || HyprlandService.wpTransitionType === "wave"
            }

            ThemedSlider {
                label: "Transition Angle"
                from: 0
                to: 360
                stepSize: 10
                value: HyprlandService.wpTransitionAngle
                suffix: "°"
                decimals: 0
                visible: HyprlandService.wpTransitionType === "wipe" || HyprlandService.wpTransitionType === "wave"
                onMoved: (val) => {
                    HyprlandService.wpTransitionAngle = Math.round(val);
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: Constants.animFast
                }

            }

        }

    }

}
