import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components

Rectangle {
    id: root

    property bool isActive: false
    property string icon: ""
    property string label: ""
    property string subtitle: ""
    property bool hasMenu: false

    signal clicked()
    signal menuClicked()

    implicitHeight: 52
    implicitWidth: 200
    radius: root.implicitHeight / 2
    color: Theme.bgSecondary
    scale: iconMouseArea.pressed || textMouseArea.pressed ? 0.98 : 1

    HoverHandler {
        id: tileHover
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Constants.sizeXs
        anchors.rightMargin: Constants.sizeXs
        spacing: Constants.sizeSm

        // Icon Circle (Interactive toggle button)
        Rectangle {
            id: iconBg

            width: Constants.size3Xl + 6
            height: Constants.size3Xl + 6
            radius: width / 2
            color: root.isActive ? Theme.accent : Theme.bgSecondary
            Layout.alignment: Qt.AlignVCenter

            SvgIcon {
                id: tileIcon

                icon: root.icon
                iconSize: 18
                flat: true
                iconColor: root.isActive ? Theme.bg : (iconMouseArea.containsMouse ? Theme.fg : Theme.muted)
                anchors.centerIn: parent
                scale: iconMouseArea.containsMouse ? 1.08 : 1

                Behavior on scale {
                    NumberAnimation {
                        duration: Constants.animFast
                        easing.type: Easing.OutQuint
                    }

                }

                Behavior on iconColor {
                    ColorAnimation {
                        duration: Constants.animFast
                    }

                }

            }

            MouseArea {
                id: iconMouseArea

                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: root.clicked()
            }

            Behavior on color {
                ColorAnimation {
                    duration: Constants.animFast
                }

            }

        }

        // Text & Menu Area (Clickable to open sub-menu)
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                ThemedText {
                    text: root.label
                    font.bold: true
                    customSize: Constants.sizeSm
                    color: Theme.fg
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                ThemedText {
                    text: root.subtitle
                    color: Theme.muted
                    customSize: Constants.sizeXs + 2
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    visible: text !== ""
                }

            }

            MouseArea {
                id: textMouseArea

                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: {
                    if (root.hasMenu)
                        root.menuClicked();
                    else
                        root.clicked();
                }
            }

        }

    }

    Behavior on scale {
        NumberAnimation {
            duration: Constants.animFast
            easing.type: Easing.OutQuad
        }

    }

}
