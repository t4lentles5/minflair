import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services

Rectangle {
    id: ccRoot

    required property var notificationService
    property bool isHovered: mouseArea.containsMouse
    property bool isPressed: mouseArea.pressed
    property int horizontalPadding: SettingsService.isBarCompact ? Constants.sizeXs : Constants.sizeLg

    implicitHeight: SettingsService.barWidgetHeight
    Layout.preferredHeight: SettingsService.barWidgetHeight
    height: parent && parent.height > 0 ? parent.height : implicitHeight
    color: SettingsService.isBarCompact ? ((isHovered || isPressed) ? Theme.bgSecondary : "transparent") : ((isHovered || isPressed) ? Theme.bgTertiary : Theme.bgSecondary)
    radius: SettingsService.isBarCompact ? Constants.sizeMd : (height / 2)
    implicitWidth: ccLayout.implicitWidth + horizontalPadding * 2
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
            notificationService: ccRoot.notificationService
        }

        SvgIcon {
            icon: "tune"
            iconColor: Theme.fg
            iconSize: Constants.sizeLg
            flat: true
        }

        NotificationsIcon {
            notificationService: ccRoot.notificationService
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
