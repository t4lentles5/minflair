import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Core
import qs.Core.Components

RowLayout {
    id: root

    property string label: ""
    property string icon: ""
    property real from: 0
    property real to: 100
    property real stepSize: 1
    property real value: 0
    property string suffix: ""
    property int decimals: 0

    signal moved(real val)
    signal iconClicked()

    Layout.fillWidth: true
    spacing: Constants.sizeMd

    SvgIcon {
        id: sliderIcon

        icon: root.icon
        iconSize: Constants.sizeLg
        flat: true
        iconColor: root.enabled ? Theme.fg : Theme.muted
        bgColor: "transparent"
        visible: root.icon !== ""
        Layout.alignment: Qt.AlignVCenter

        MouseArea {
            anchors.fill: parent
            cursorShape: parent.visible ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: root.iconClicked()
        }

    }

    ThemedText {
        text: root.label
        font.bold: true
        color: root.enabled ? Theme.fg : Theme.muted
        visible: root.label !== ""
        elide: Text.ElideRight
    }

    BaseSlider {
        id: internalSlider

        Layout.fillWidth: true
        from: root.from
        to: root.to
        stepSize: root.stepSize
        value: root.value
        color: root.enabled ? Theme.accent : Theme.muted
        enabled: root.enabled
        onMoved: root.moved(value)
    }

    Rectangle {
        id: valueBadge

        Layout.preferredWidth: Math.max(48, valueText.implicitWidth + Constants.sizeSm)
        Layout.preferredHeight: 22
        radius: Constants.sizeLg
        color: Theme.bgSecondary

        ThemedText {
            id: valueText

            anchors.centerIn: parent
            text: root.value.toFixed(root.decimals) + root.suffix
            customSize: Constants.sizeXs + 2
            font.bold: true
            color: !root.enabled ? Theme.muted : Theme.fg

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

    }

}
