import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services

RowLayout {
    id: ccRootGroup

    required property var notificationService
    property int horizontalPadding: 10

    spacing: Constants.sizeSm

    Rectangle {
        id: ccRoot

        property bool isHovered: mouseArea.containsMouse
        property bool isPressed: mouseArea.pressed

        implicitHeight: SettingsService.barWidgetHeight
        Layout.preferredHeight: SettingsService.barWidgetHeight
        color: (isHovered || isPressed) ? Theme.bgTertiary : Theme.bgSecondary
        radius: height / 2
        implicitWidth: ccLayout.implicitWidth + ccRootGroup.horizontalPadding * 2
        scale: isPressed ? 0.95 : (isHovered ? 1.02 : 1)

        MouseArea {
            id: mouseArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: AppState.togglePopup("controlCenter")
        }

        RowLayout {
            id: ccLayout

            anchors.centerIn: parent
            spacing: 2

            BatteryIcon {
                notificationService: ccRootGroup.notificationService
            }

            SvgIcon {
                icon: "tune"
                iconColor: Theme.fg
                iconSize: Constants.sizeLg
                flat: true
            }

        }

        Behavior on color {
            ColorAnimation {
                duration: Constants.animFast
            }

        }

        Behavior on scale {
            NumberAnimation {
                duration: Constants.animFast
                easing.type: Easing.OutBack
            }

        }

    }

    Rectangle {
        id: notifRoot

        property bool isHovered: notifMouseArea.containsMouse
        property bool isPressed: notifMouseArea.pressed

        implicitHeight: SettingsService.barWidgetHeight
        Layout.preferredHeight: SettingsService.barWidgetHeight
        color: (isHovered || isPressed) ? Theme.bgTertiary : Theme.bgSecondary
        radius: height / 2
        implicitWidth: notifLayout.implicitWidth + ccRootGroup.horizontalPadding * 2
        scale: isPressed ? 0.95 : (isHovered ? 1.02 : 1)

        MouseArea {
            id: notifMouseArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: AppState.togglePopup("notificationsCenter")
        }

        RowLayout {
            id: notifLayout

            anchors.centerIn: parent
            spacing: 2

            NotificationsIcon {
                notificationService: ccRootGroup.notificationService
            }

        }

        Behavior on color {
            ColorAnimation {
                duration: Constants.animFast
            }

        }

        Behavior on scale {
            NumberAnimation {
                duration: Constants.animFast
                easing.type: Easing.OutBack
            }

        }

    }

}
