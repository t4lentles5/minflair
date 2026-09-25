import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Settings.Components

AppContainer {
    id: root

    AppGroup {
        title: "Animations"
        icon: "sparkles"

        SettingSpinBox {
            label: "Global Animation Speed"
            description: "Control UI transition and fade speed"
            from: 0
            to: 2
            stepSize: 0.1
            value: HyprlandService.enableAnimations ? HyprlandService.animationSpeedFactor : 0
            suffix: "x"
            decimals: 1
            allowOff: true
            offText: "Off"
            onMoved: (val) => {
                if (val <= 0.001) {
                    HyprlandService.enableAnimations = false;
                } else {
                    if (!HyprlandService.enableAnimations)
                        HyprlandService.enableAnimations = true;

                    HyprlandService.animationSpeedFactor = Number(val.toFixed(1));
                }
            }
        }

    }

    AppGroup {
        title: "Compositor Effects"
        icon: "hyprland"

        SettingSpinBox {
            label: "Global Opacity"
            description: "Transparency of windows and shell"
            from: 50
            to: 100
            stepSize: 5
            value: HyprlandService.hyprActiveOpacity
            defaultValue: 100
            suffix: "%"
            onMoved: (val) => {
                let intVal = Math.round(val);
                HyprlandService.hyprActiveOpacity = intVal;
                HyprlandService.hyprInactiveOpacity = intVal;
                HyprlandService.applyHyprlandSettings();
                Theme.bgOpacity = intVal / 100;
                Theme.saveScheme();
            }
        }

        SettingToggle {
            id: blurToggle

            label: "Enable Window & Panel Blur"
            onCheckedChanged: {
                if (checked !== HyprlandService.hyprBlur)
                    HyprlandService.hyprBlur = checked;

            }

            Binding on checked {
                value: HyprlandService.hyprBlur
            }

        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Constants.sizeMd
            enabled: HyprlandService.hyprBlur
            opacity: enabled ? 1 : 0.5

            SettingSpinBox {
                label: "Blur Size"
                from: 1
                to: 15
                stepSize: 1
                value: HyprlandService.hyprBlurSize
                defaultValue: 6
                onMoved: (val) => {
                    HyprlandService.hyprBlurSize = Math.round(val);
                }
            }

            SettingSpinBox {
                label: "Blur Passes"
                from: 1
                to: 10
                stepSize: 1
                value: HyprlandService.hyprBlurPasses
                defaultValue: 4
                onMoved: (val) => {
                    HyprlandService.hyprBlurPasses = Math.round(val);
                }
            }

        }

        SettingToggle {
            id: shadowToggle

            label: "Enable Window & Shell Shadows"
            onCheckedChanged: {
                if (checked !== HyprlandService.hyprShadow)
                    HyprlandService.hyprShadow = checked;

            }

            Binding on checked {
                value: HyprlandService.hyprShadow
            }

        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Constants.sizeMd
            enabled: HyprlandService.hyprShadow
            opacity: enabled ? 1 : 0.5

            SettingSpinBox {
                label: "Shadow Range"
                from: 1
                to: 60
                stepSize: 1
                value: HyprlandService.hyprShadowRange
                defaultValue: 20
                suffix: "px"
                onMoved: (val) => {
                    HyprlandService.hyprShadowRange = Math.round(val);
                }
            }

            SettingSpinBox {
                label: "Shadow Render Power"
                from: 1
                to: 4
                stepSize: 1
                value: HyprlandService.hyprShadowRenderPower
                defaultValue: 2
                onMoved: (val) => {
                    HyprlandService.hyprShadowRenderPower = Math.round(val);
                }
            }

        }

    }

}
