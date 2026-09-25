import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Effects
import qs.Core
import qs.Core.Components
import qs.Core.Services

Item {
    id: root

    property bool enableShadow: true
    property real radius: height / 2
    default property alias content: shape.data

    ThemedShadow {
        anchors.fill: shape
        radius: shape.radius
        visible: root.enableShadow && HyprlandService.hyprShadow && opacity > 0.001
    }

    Rectangle {
        id: shape

        anchors.fill: parent
        clip: true
        radius: root.radius
        color: Theme.bg
        border.width: 0
        antialiasing: true
        border.color: "transparent"

        Behavior on color {
            ColorAnimation {
                duration: Constants.animNormal
            }

        }

    }

}
