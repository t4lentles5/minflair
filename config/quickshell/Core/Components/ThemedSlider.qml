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
    property string suffix: "%"
    property int decimals: 0
    property color accentColor: Theme.accent
    property real from: 0
    property real to: 100
    property real stepSize: 1
    property real value: 0
    property bool enabled: true
    property bool showValue: true
    readonly property bool pressed: internalSlider.pressed

    signal moved(real val)
    signal iconClicked()

    Layout.fillWidth: true
    implicitHeight: root.label !== "" ? (labelRow.implicitHeight + mainRow.implicitHeight + 4) : Constants.size2Xl + 2

    ColumnLayout {
        anchors.fill: parent
        spacing: Constants.size2Xs

        RowLayout {
            id: labelRow

            Layout.fillWidth: true
            visible: root.label !== ""

            ThemedText {
                text: root.label
                font.bold: true
                color: Theme.fg
                Layout.fillWidth: true
            }

            ThemedText {
                text: {
                    let v = root.decimals > 0 ? root.value.toFixed(root.decimals) : Math.round(root.value);
                    return v + (root.suffix !== "" ? root.suffix : "");
                }
                font.bold: true
                color: Theme.muted
                visible: root.showValue && root.icon === ""
            }

        }

        RowLayout {
            id: mainRow

            Layout.fillWidth: true
            Layout.preferredHeight: Constants.size2Xl + 2
            spacing: Constants.sizeSm

            // Left Icon
            SvgIcon {
                id: sliderIcon

                icon: root.icon
                iconSize: 18
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

                Behavior on iconColor {
                    ColorAnimation {
                        duration: Constants.animFast
                    }

                }

            }

            // Center Slider
            Slider {
                id: internalSlider

                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                implicitHeight: Constants.size2Xl + 2
                from: root.from
                to: root.to
                stepSize: root.stepSize
                value: root.value
                enabled: root.enabled
                leftPadding: 0
                rightPadding: 0
                topPadding: 0
                bottomPadding: 0
                onMoved: {
                    root.moved(internalSlider.value);
                }

                HoverHandler {
                    id: sliderHover

                    cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                }

                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: (event) => {
                        let step = (root.to - root.from) / 20;
                        if (root.stepSize > 0 && root.stepSize > step)
                            step = root.stepSize;

                        let delta = event.angleDelta.y > 0 ? step : -step;
                        let newVal = Math.max(root.from, Math.min(root.to, root.value + delta));
                        if (newVal !== root.value)
                            root.moved(newVal);

                    }
                }

                background: Rectangle {
                    id: trackRect

                    x: internalSlider.leftPadding
                    y: Math.round(internalSlider.topPadding + (internalSlider.availableHeight - height) / 2)
                    width: internalSlider.availableWidth
                    height: Constants.size2Xs + 2
                    radius: height / 2
                    color: Theme.bgSecondary

                    Rectangle {
                        id: progressRect

                        width: {
                            if (internalSlider.value <= internalSlider.from)
                                return 0;

                            if (internalSlider.value >= internalSlider.to)
                                return parent.width;

                            return Math.max(0, Math.min(parent.width, sliderHandle.x + sliderHandle.width / 2));
                        }
                        height: parent.height
                        radius: height / 2
                        color: root.enabled ? root.accentColor : Theme.muted

                        Behavior on width {
                            enabled: HyprlandService.enableAnimations && !internalSlider.pressed && !sliderHover.hovered

                            NumberAnimation {
                                duration: Constants.animFast
                                easing.type: Easing.OutQuad
                            }

                        }

                    }

                }

                handle: Rectangle {
                    id: sliderHandle

                    readonly property real trackWidth: internalSlider.availableWidth - width

                    x: Math.round(internalSlider.leftPadding + internalSlider.visualPosition * trackWidth)
                    y: Math.round(internalSlider.topPadding + (internalSlider.availableHeight - height) / 2)
                    width: 5
                    height: Constants.size2Xl
                    radius: height / 2
                    color: root.enabled ? root.accentColor : Theme.muted
                    scale: internalSlider.pressed ? 1.15 : (sliderHover.hovered ? 1.08 : 1)
                    transformOrigin: Item.Center

                    Behavior on scale {
                        NumberAnimation {
                            duration: Constants.animFast
                            easing.type: Easing.OutBack
                        }

                    }

                    Behavior on x {
                        enabled: HyprlandService.enableAnimations && !internalSlider.pressed && !sliderHover.hovered

                        NumberAnimation {
                            duration: Constants.animFast
                            easing.type: Easing.OutQuad
                        }

                    }

                }

            }

            // Right Value
            ThemedText {
                id: valueLabel

                text: {
                    let v = root.decimals > 0 ? root.value.toFixed(root.decimals) : Math.round(root.value);
                    return v + (root.suffix !== "" ? root.suffix : "");
                }
                font.bold: true
                color: root.enabled ? Theme.fg : Theme.muted
                visible: root.showValue
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 38
                horizontalAlignment: Text.AlignRight
            }

        }

    }

}
