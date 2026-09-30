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

    signal clicked()
    signal menuClicked()

    implicitHeight: Constants.size4Xl + (Constants.sizeXs * 2)
    implicitWidth: 200
    radius: root.implicitHeight / 2
    color: Theme.bgSecondary
    scale: iconMouseArea.pressed || textMouseArea.pressed ? 0.95 : 1

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Constants.sizeXs
        anchors.rightMargin: Constants.sizeXs
        spacing: Constants.sizeMd

        Rectangle {
            id: iconBg

            implicitWidth: Constants.size4Xl
            implicitHeight: Constants.size4Xl
            radius: iconBg.height / 2
            color: root.isActive ? Theme.accent : Theme.bgSecondary
            Layout.alignment: Qt.AlignVCenter

            SvgIcon {
                id: tileIcon

                icon: root.icon
                iconSize: Constants.sizeLg
                flat: true
                iconColor: root.isActive ? Theme.bg : Theme.fg
                bgColor: "transparent"
                anchors.centerIn: parent
                scale: iconMouseArea.containsMouse ? 1.05 : 1

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

        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

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
                    customSize: Constants.sizeSm
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    visible: text !== ""
                }

            }

            MouseArea {
                id: textMouseArea

                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.menuClicked()
            }

        }

    }

    Behavior on color {
        ColorAnimation {
            duration: Constants.animNormal
        }

    }

    Behavior on scale {
        NumberAnimation {
            duration: Constants.animFast
            easing.type: Easing.OutBack
        }

    }

}
