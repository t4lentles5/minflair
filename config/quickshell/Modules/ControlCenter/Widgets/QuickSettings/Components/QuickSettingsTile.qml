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
    property real chevronAreaWidth: 36
    readonly property bool hovered: mouseArea.containsMouse
    readonly property bool pressed: mouseArea.pressed

    signal clicked()
    signal menuClicked()

    implicitHeight: Constants.size5Xl
    radius: Constants.sizeXl
    color: Theme.bgSecondary
    scale: pressed ? 0.95 : 1

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        anchors.rightMargin: root.isActive ? root.chevronAreaWidth : 0
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: {
            root.clicked();
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Constants.sizeLg
        anchors.rightMargin: root.isActive ? Constants.sizeXs : Constants.sizeLg
        spacing: Constants.sizeMd

        Rectangle {
            id: iconBg

            implicitWidth: 20
            implicitHeight: 20
            color: "transparent"
            Layout.alignment: Qt.AlignVCenter

            SvgIcon {
                id: tileIcon

                icon: root.icon
                iconSize: Constants.sizeXl
                flat: true
                iconColor: root.isActive ? Theme.accent : Theme.muted
                bgColor: "transparent"
                anchors.centerIn: parent
                scale: root.hovered ? 1.1 : 1

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

        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            ThemedText {
                text: root.label
                font.bold: true
                color: root.isActive ? Theme.fg : Theme.muted
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            ThemedText {
                text: root.subtitle
                color: Theme.muted
                elide: Text.ElideRight
                Layout.fillWidth: true
                visible: text !== ""
            }

        }

        RowLayout {
            visible: root.isActive
            spacing: Constants.sizeXs
            Layout.alignment: Qt.AlignVCenter

            Divider {
                vertical: true
                Layout.preferredHeight: 24
                Layout.fillHeight: false
            }

            SvgIconButton {
                id: chevronBtn

                icon: "chevron-right"
                iconSize: Constants.sizeSm
                iconColor: Theme.accent
                flat: true
                padding: 4
                onClicked: {
                    root.menuClicked();
                }
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
