import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Core
import qs.Core.Components
import qs.Core.Services

SettingRowTemplate {
    id: root

    property var model: []
    property var currentValue

    signal activated(var value)

    Rectangle {
        id: controlContainer

        property real indicatorX: 0
        property real indicatorWidth: 0

        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
        implicitHeight: Constants.size3Xl
        implicitWidth: row.implicitWidth
        radius: Constants.sizeXs
        color: Theme.bgSecondary
        border.width: 1
        border.color: Theme.border

        Rectangle {
            id: activeIndicator

            x: controlContainer.indicatorX
            width: controlContainer.indicatorWidth
            height: controlContainer.height
            color: "transparent"

            Rectangle {
                anchors.fill: parent
                anchors.margins: Constants.size3Xs
                radius: Constants.sizeXs
                color: Theme.bgAccent
            }

            Behavior on x {
                NumberAnimation {
                    duration: Constants.animNormal
                    easing.type: Easing.OutQuart
                }

            }

            Behavior on width {
                NumberAnimation {
                    duration: Constants.animNormal
                    easing.type: Easing.OutQuart
                }

            }

        }

        Row {
            id: row

            anchors.fill: parent

            Repeater {
                model: root.model

                delegate: Item {
                    property bool isActive: root.currentValue === modelData.value

                    width: Math.max(54, textItem.implicitWidth + 20)
                    height: controlContainer.height
                    onIsActiveChanged: {
                        if (isActive) {
                            controlContainer.indicatorX = x;
                            controlContainer.indicatorWidth = width;
                        }
                    }
                    Component.onCompleted: {
                        if (isActive) {
                            controlContainer.indicatorX = x;
                            controlContainer.indicatorWidth = width;
                        }
                    }
                    onXChanged: {
                        if (isActive)
                            controlContainer.indicatorX = x;

                    }
                    onWidthChanged: {
                        if (isActive)
                            controlContainer.indicatorWidth = width;

                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: Constants.size3Xs
                        radius: Constants.sizeXs
                        color: mouseArea.containsMouse && !isActive ? Theme.bgSecondary : "transparent"

                        ThemedText {
                            id: textItem

                            anchors.centerIn: parent
                            text: modelData.text
                            font.weight: isActive ? Font.Bold : Font.Normal
                            customSize: 11
                            color: isActive ? Theme.fg : (mouseArea.containsMouse ? Theme.fg : Theme.muted)

                            Behavior on color {
                                ColorAnimation {
                                    duration: Constants.animFast
                                }

                            }

                        }

                        MouseArea {
                            id: mouseArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (!isActive)
                                    root.activated(modelData.value);

                            }
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: Constants.animFast
                            }

                        }

                    }

                }

            }

        }

    }

}
