import QtQuick
import qs.Core
import qs.Core.Components
import qs.Core.Services

Item {
    id: root

    property var widget
    readonly property bool isOpen: widget ? widget.isOpen : false
    readonly property real preferredWidth: widget ? widget.smoothPreferredWidth : 0
    readonly property real preferredHeight: widget ? widget.smoothPreferredHeight : 0
    readonly property color backgroundColor: widget ? widget.backgroundColor : Theme.bg
    readonly property real windowRadius: widget ? widget.smoothWindowRadius : 0
    readonly property real contentPadding: widget ? widget.smoothContentPadding : 0
    readonly property bool positionAtBottom: widget ? widget.positionAtBottom : false
    property alias contentSlot: contentLayoutContainer
    property alias container: mainContainer
    property bool isHandover: false
    property bool isClosing: false
    readonly property real bounceProgress: widget ? widget.bounceProgress : 0

    anchors.fill: parent

    Item {
        id: mainContainer

        readonly property real closedY: root.height > 0 ? (root.height + 20) : 1200
        readonly property real targetY: positionAtBottom ? Math.round(root.height - preferredHeight - 8) : Math.round((root.height - preferredHeight) / 2)

        width: Math.round(preferredWidth)
        height: Math.round(preferredHeight)
        anchors.horizontalCenter: parent.horizontalCenter
        transformOrigin: positionAtBottom ? Item.Bottom : Item.Center
        y: positionAtBottom ? Math.round(closedY + (targetY - closedY) * bounceProgress) : Math.round(targetY + (1 - bounceProgress) * 20)
        scale: positionAtBottom ? 1 : (0.96 + 0.04 * bounceProgress)

        ThemedShadow {
            anchors.fill: floatingBg
            radius: floatingBg.radius
            active: (widget ? widget.enableShadow : true) && HyprlandService.hyprShadow
            opacity: 1
        }

        Rectangle {
            id: floatingBg

            anchors.fill: parent
            radius: Math.round(windowRadius)
            color: root.backgroundColor
            clip: true

            Item {
                id: contentLayoutContainer

                anchors.fill: parent
                anchors.margins: contentPadding
                clip: contentPadding > 0
            }

        }

        // Prevent clicks on the container from reaching the dismiss area
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

    }

}
