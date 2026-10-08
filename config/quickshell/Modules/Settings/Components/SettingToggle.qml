import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Core
import qs.Core.Components
import qs.Core.Services

SettingRowTemplate {
    id: root

    property alias checked: settingSwitch.checked

    signal toggled(bool checked)

    Switch {
        id: settingSwitch

        z: 10
        Layout.alignment: Qt.AlignVCenter
        opacity: root.enabled ? 1 : 0.5
        onToggled: root.toggled(checked)
        implicitWidth: Constants.size4Xl
        implicitHeight: Constants.sizeXl + 2

        HoverHandler {
            cursorShape: Qt.PointingHandCursor
        }

        indicator: Rectangle {
            implicitWidth: Constants.size4Xl
            implicitHeight: Constants.sizeXl + 2
            radius: height / 2
            color: settingSwitch.checked ? Theme.accent : Theme.bgSecondary
            border.width: 1
            border.color: settingSwitch.checked ? Theme.accent : Theme.border

            Rectangle {
                id: knob

                x: settingSwitch.checked ? parent.width - width - 3 : 3
                y: (parent.height - height) / 2
                width: Constants.sizeLg
                height: Constants.sizeLg
                radius: width / 2
                color: settingSwitch.checked ? "#ffffff" : (Theme.isDark ? Theme.muted : "#ffffff")
                scale: settingSwitch.pressed ? 0.9 : (settingSwitch.hovered ? 1.05 : 1)
                layer.enabled: true

                layer.effect: DropShadow {
                    transparentBorder: true
                    color: Theme.shadow
                    radius: Constants.size3Xs + 1
                    samples: 7
                    verticalOffset: 1
                }

                Behavior on x {
                    NumberAnimation {
                        duration: Constants.animFast
                        easing.type: Easing.OutCubic
                    }

                }

                Behavior on scale {
                    NumberAnimation {
                        duration: Constants.animFast
                        easing.type: Easing.OutBack
                    }

                }

                Behavior on color {
                    ColorAnimation {
                        duration: Constants.animFast
                    }

                }

            }

            Behavior on color {
                ColorAnimation {
                    duration: Constants.animFast
                }

            }

            Behavior on border.color {
                ColorAnimation {
                    duration: Constants.animFast
                }

            }

        }

    }

}
