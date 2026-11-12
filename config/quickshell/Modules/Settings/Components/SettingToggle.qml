import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import qs.Core
import qs.Core.Components
import qs.Core.Services

SettingRowTemplate {
    id: root

    property alias checked: settingSwitch.checked
    // Optional two-way binding to a service property. When both are set the
    // toggle shows the property value, writes user changes back to it, and
    // keeps following it when it changes elsewhere. Without it the binding
    // is dropped as soon as the user clicks, and the toggle stops tracking
    // the property.
    property var bindTarget: null
    property string bindProperty: ""

    signal toggled(bool checked)

    Binding {
        target: root
        property: "checked"
        value: root.bindTarget !== null && root.bindProperty !== ""
            ? root.bindTarget[root.bindProperty]
            : root.checked
        when: root.bindTarget !== null && root.bindProperty !== ""
    }

    onCheckedChanged: {
        if (root.bindTarget !== null && root.bindProperty !== "") {
            let current = root.bindTarget[root.bindProperty];
            if (current !== root.checked)
                root.bindTarget[root.bindProperty] = root.checked;

        }
    }

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
                color: settingSwitch.checked ? Theme.white : (Theme.isDark ? Theme.muted : Theme.white)
                scale: settingSwitch.pressed ? 0.9 : (settingSwitch.hovered ? 1.05 : 1)
                layer.enabled: true

                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Theme.shadow
                    blurMax: (Constants.size3Xs + 1) * 2
                    shadowBlur: 1
                    shadowVerticalOffset: 1
                    shadowHorizontalOffset: 0
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
