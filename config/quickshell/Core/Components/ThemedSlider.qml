import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services

Item {
    id: root

    property string label: ""
    property string icon: ""
    property string suffix: ""
    property int decimals: 0
    property color accentColor: Theme.accent
    property real from: 0
    property real to: 100
    property real stepSize: 1
    property real value: 0
    property bool enabled: true

    signal moved(real val)
    signal iconClicked()

    Layout.fillWidth: true
    implicitHeight: 32

    Slider {
        id: internalSlider

        anchors.fill: parent
        from: root.from
        to: root.to
        stepSize: root.stepSize
        value: root.value
        enabled: root.enabled
        onMoved: {
            root.moved(internalSlider.value);
        }

        HoverHandler {
            id: sliderHover

            cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        }

        background: Rectangle {
            anchors.fill: parent
            color: Theme.bg // Contrast against bgSecondary cards
            radius: height / 2

            Rectangle {
                width: internalSlider.visualPosition * parent.width
                height: parent.height
                color: root.enabled ? root.accentColor : Theme.muted
                radius: height / 2

                Behavior on width {
                    enabled: HyprlandService.enableAnimations

                    NumberAnimation {
                        duration: Constants.animFast
                        easing.type: Easing.OutQuad
                    }

                }

            }

        }

        // Empty handle since we don't need a visible knob for a thick slider
        handle: Item {
        }

    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Constants.sizeSm
        anchors.rightMargin: Constants.sizeSm
        spacing: Constants.sizeSm

        SvgIcon {
            id: sliderIcon

            icon: root.icon
            iconSize: Constants.sizeMd
            flat: true
            iconColor: Theme.bg
            bgColor: "transparent"
            visible: root.icon !== ""
            Layout.alignment: Qt.AlignVCenter

            MouseArea {
                anchors.fill: parent
                cursorShape: parent.visible ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.iconClicked()
            }

            Behavior on iconColor {
                ColorAnimation {
                    duration: Constants.animFast
                }

            }

        }

    }

}
