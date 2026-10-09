import QtQuick
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Bar
import qs.Modules.Bar.Components

Item {
    id: root

    property var notificationService: null

    Rectangle {
        anchors.fill: parent
        color: Theme.bg
        radius: 0

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: Theme.border
        }

    }

    Row {
        id: leftSection

        anchors.left: parent.left
        anchors.leftMargin: Constants.sizeXs
        anchors.verticalCenter: parent.verticalCenter
        height: Constants.size2Xl + 4
        spacing: Constants.sizeXs

        // Badge Gaming Mode
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            height: Constants.size2Xl
            width: badgeContent.implicitWidth + Constants.sizeLg
            color: Theme.accent
            radius: 0

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    DisplayProfileService.autoActivatedByDaemon = false;
                    DisplayProfileService.gameModeActive = false;
                }
            }

            Row {
                id: badgeContent

                anchors.centerIn: parent
                spacing: 6

                SvgIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "gamepad-filled"
                    iconSize: Constants.sizeMd
                    iconColor: Theme.bg
                    flat: true
                }

                ThemedText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "GAMING"
                    font.bold: true
                    customSize: 11
                    color: Theme.bg
                }

            }

        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            height: Constants.sizeLg + 2
            color: Theme.border
        }

        Workspaces {
            anchors.verticalCenter: parent.verticalCenter
            compact: true
            bgColor: "transparent"
        }

    }

    Rectangle {
        id: centerSection

        anchors.centerIn: parent
        height: Constants.size2Xl + 4
        width: Math.max(70, clockContent.implicitWidth + 24)
        color: AppState.isWidgetOpen("dashboard") ? Theme.bgAccent : (clockMouse.containsMouse ? Theme.bgTertiary : Theme.bgSecondary)
        radius: 0
        border.width: 1
        border.color: Theme.border

        MouseArea {
            id: clockMouse

            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: {
                AppState.toggleWidget("dashboard");
            }
        }

        ClockButton {
            id: clockContent

            anchors.centerIn: parent
        }

    }

    Row {
        id: rightSection

        anchors.right: parent.right
        anchors.rightMargin: Constants.sizeXs
        anchors.verticalCenter: parent.verticalCenter
        height: Constants.size2Xl + 4
        spacing: Constants.sizeXs

        MediaButton {
            anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            height: Constants.size2Xl + 4
            width: Math.max(64, statusControlsRow.implicitWidth + 12)
            color: Theme.bgSecondary
            radius: 0
            border.width: 1
            border.color: Theme.border

            Row {
                id: statusControlsRow

                anchors.centerIn: parent
                spacing: Constants.size2Xs

                ControlCenterButton {
                    anchors.verticalCenter: parent.verticalCenter
                    notificationService: root.notificationService
                }

                NotificationsButton {
                    anchors.verticalCenter: parent.verticalCenter
                    notificationService: root.notificationService
                }

                SystemTrayGroup {
                    anchors.verticalCenter: parent.verticalCenter
                    hasBackground: false
                    compact: true
                }

            }

        }

        PowerButton {
            anchors.verticalCenter: parent.verticalCenter
            widgetId: "powerMenu"
        }

    }

}
