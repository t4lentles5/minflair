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
    default property alias content: contentSlot.data

    ThemedShadow {
        anchors.fill: shape
        radius: shape.radius
        visible: root.enableShadow && HyprlandService.hyprShadow && opacity > 0.001
    }

    Rectangle {
        id: shape

        anchors.fill: parent
        radius: root.radius
        color: Theme.bg
        antialiasing: true
        layer.enabled: true
        layer.smooth: true
        layer.samples: 4

        Behavior on color {
            ColorAnimation {
                duration: Constants.animNormal
            }

        }

    }

    Item {
        id: contentSlot

        anchors.fill: parent
    }

}
