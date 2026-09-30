import Qt5Compat.GraphicalEffects
import QtQuick
import Quickshell
import qs.Core
import qs.Core.Services

Rectangle {
    id: root

    property string icon: ""
    property bool isActive: false
    property color iconColor: isActive ? Theme.fg : Theme.fg
    property bool flat: false
    property color bgColor: isActive ? Theme.accent : (flat ? "transparent" : Theme.bg)
    property int iconSize: Constants.sizeLg
    property bool isCircle: false
    property bool useOriginalColors: false
    readonly property int scaledIconSize: Math.round(iconSize * SettingsService.fontScale)
    readonly property int status: iconImage.status

    signal clicked(var mouse)

    color: root.bgColor
    implicitWidth: flat ? scaledIconSize : scaledIconSize + Constants.sizeLg
    implicitHeight: flat ? scaledIconSize : scaledIconSize + Constants.sizeLg
    radius: isCircle ? implicitWidth / 2 : Constants.sizeXs

    Image {
        id: iconImage

        anchors.centerIn: parent
        source: {
            if (!root.icon)
                return "";

            if (root.icon.startsWith("image://") || root.icon.startsWith("file://") || root.icon.startsWith("/"))
                return root.icon;

            return `${Quickshell.shellDir}/assets/${root.icon}.svg`;
        }
        width: root.scaledIconSize
        height: root.scaledIconSize
        sourceSize.width: root.scaledIconSize
        sourceSize.height: root.scaledIconSize
        visible: root.useOriginalColors
    }

    ColorOverlay {
        anchors.fill: iconImage
        source: iconImage
        color: Qt.rgba(root.iconColor.r, root.iconColor.g, root.iconColor.b, 1)
        opacity: root.iconColor.a
        visible: !root.useOriginalColors
    }

}
