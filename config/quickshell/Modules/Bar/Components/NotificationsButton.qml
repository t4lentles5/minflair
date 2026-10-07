import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services

Rectangle {
    id: root

    property var notificationService: null
    property var notificationsCenterWidget: null
    property bool isHovered: mouseArea.containsMouse
    property bool isPressed: mouseArea.pressed
    readonly property bool isActive: AppState.isWidgetOpen("notificationsCenter")

    implicitHeight: SettingsService.barWidgetHeight
    implicitWidth: height
    width: implicitWidth
    height: implicitHeight
    Layout.preferredHeight: implicitHeight
    Layout.preferredWidth: implicitWidth
    Layout.alignment: Qt.AlignVCenter
    color: isActive ? Theme.bgAccent : (isHovered ? Theme.bgSecondary : "transparent")
    radius: DisplayProfileService.gameModeActive ? 0 : height / 2
    visible: true
    scale: DisplayProfileService.gameModeActive ? 1 : (isPressed ? 0.92 : (isHovered ? 1.05 : 1))

    NotificationsIcon {
        id: notifIcon

        anchors.centerIn: parent
        notificationService: root.notificationService
        iconColor: root.isActive ? Theme.accent : ((notificationService && notificationService.dndEnabled) ? Theme.muted : Theme.fg)

        Behavior on iconColor {
            ColorAnimation {
                duration: Constants.animFast
            }

        }

    }

    MouseArea {
        id: mouseArea

        z: 10
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            AppState.toggleWidget("notificationsCenter");
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
