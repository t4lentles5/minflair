import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services

Rectangle {
    id: root

    property var widget: null
    property string popupId: ""
    property string icon: ""
    property int iconSize: Constants.sizeLg
    property int fontSize: Constants.sizeSm
    property color iconColor: Theme.fg
    property bool hasBackground: false
    property color backgroundColor: Theme.bgSecondary
    property color hoverBackgroundColor: Theme.bgTertiary

    implicitHeight: hasBackground ? SettingsService.barWidgetHeight : (svgIcon.implicitHeight > 0 ? svgIcon.implicitHeight : iconSize)
    implicitWidth: hasBackground ? height : (svgIcon.implicitWidth > 0 ? svgIcon.implicitWidth : iconSize)
    Layout.preferredHeight: hasBackground ? SettingsService.barWidgetHeight : implicitHeight
    Layout.preferredWidth: implicitWidth
    radius: hasBackground ? height / 2 : Constants.sizeLg
    color: hasBackground ? ((mouseArea.containsMouse || mouseArea.pressed) ? hoverBackgroundColor : backgroundColor) : "transparent"
    scale: mouseArea.pressed ? 0.95 : (mouseArea.containsMouse ? 1.05 : 1)

    SvgIcon {
        id: svgIcon

        anchors.centerIn: parent
        icon: root.icon
        iconSize: root.iconSize
        flat: true
        iconColor: (!root.hasBackground && mouseArea.containsMouse) ? Theme.accent : root.iconColor
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.widget)
                root.widget.isOpen = !root.widget.isOpen;
            else if (root.popupId !== "")
                AppState.togglePopup(root.popupId);
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
