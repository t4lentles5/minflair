import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components

Item {
    id: root

    property string titleText: ""
    property string subtitleText: ""
    property string iconName: ""
    property bool isActive: false
    property bool showLock: false

    signal clicked()
    signal actionClicked()
    signal disconnectClicked()
    signal forgetClicked()

    Layout.fillWidth: true
    implicitHeight: isActive ? contentCol.implicitHeight + Constants.sizeSm * 2 : 36

    Rectangle {
        anchors.fill: parent
        radius: Constants.sizeLg
        color: bgHover.containsMouse ? Theme.bgTertiary : Theme.bgSecondary

        MouseArea {
            id: bgHover

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.clicked()
        }

        Behavior on color {
            ColorAnimation {
                duration: Constants.animFast
            }

        }

    }

    ColumnLayout {
        id: contentCol

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Constants.sizeSm
        spacing: Constants.sizeSm

        RowLayout {
            Layout.fillWidth: true
            spacing: Constants.sizeSm

            SvgIcon {
                icon: root.iconName
                iconColor: root.isActive ? Theme.accent : Theme.fg
                iconSize: Constants.sizeLg
                flat: true
                opacity: root.isActive ? 1 : 0.7
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                ThemedText {
                    text: root.titleText
                    color: root.isActive ? Theme.accent : Theme.fg
                    font.bold: root.isActive
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                ThemedText {
                    visible: root.isActive && root.subtitleText !== ""
                    text: root.subtitleText
                    color: Theme.muted
                    customSize: Constants.sizeXs + 2
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

            }

            SvgIcon {
                visible: root.showLock && !root.isActive
                icon: "lock"
                iconColor: Theme.muted
                iconSize: Constants.sizeSm
                flat: true
                opacity: 0.5
            }

            SvgIconButton {
                visible: root.isActive
                iconColor: Theme.accent
                iconSize: Constants.sizeSm
                flat: true
                onClicked: root.actionClicked()
            }

            SvgIcon {
                visible: root.isActive
                icon: "check"
                iconColor: Theme.accent
                iconSize: Constants.sizeSm
                flat: true
            }

        }

        RowLayout {
            visible: root.isActive
            Layout.fillWidth: true
            spacing: Constants.sizeSm
            Layout.topMargin: Constants.sizeXs

            Rectangle {
                id: disconnectBtn

                Layout.fillWidth: true
                Layout.preferredHeight: 32
                color: discHover.containsMouse ? Theme.bgTertiary : Theme.bgSecondary
                radius: Constants.sizeMd

                RowLayout {
                    anchors.centerIn: parent
                    spacing: Constants.sizeXs

                    SvgIcon {
                        icon: root.iconName === "bluetooth" ? "bluetooth-off" : "wifi-off"
                        iconColor: Theme.fg
                        iconSize: Constants.sizeSm
                        flat: true
                    }

                    ThemedText {
                        text: "Disconnect"
                        color: Theme.fg
                        customSize: Constants.sizeSm
                    }

                }

                MouseArea {
                    id: discHover

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.disconnectClicked()
                }

            }

            Rectangle {
                id: forgetBtn

                Layout.fillWidth: true
                Layout.preferredHeight: 32
                color: forgetHover.containsMouse ? Theme.bgTertiary : Theme.bgSecondary
                radius: Constants.sizeMd

                RowLayout {
                    anchors.centerIn: parent
                    spacing: Constants.sizeXs

                    ThemedText {
                        text: "Forget"
                        color: Theme.fg
                        customSize: Constants.sizeSm
                    }

                }

                MouseArea {
                    id: forgetHover

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.forgetClicked()
                }

            }

        }

    }

    Behavior on implicitHeight {
        NumberAnimation {
            duration: Constants.animFast
            easing.type: Easing.OutCubic
        }

    }

}
