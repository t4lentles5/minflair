import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
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

        readonly property real closedY: root.height > 0 ? root.height + 20 : 1200
        readonly property real targetY: positionAtBottom ? (root.height - preferredHeight - 8) : ((root.height - preferredHeight) / 2)

        width: preferredWidth
        height: preferredHeight
        anchors.horizontalCenter: parent.horizontalCenter
        transformOrigin: positionAtBottom ? Item.Bottom : Item.Center
        y: Math.round(closedY + (targetY - closedY) * bounceProgress)
        scale: 0.92 + 0.08 * bounceProgress

        ThemedShadow {
            anchors.fill: floatingBg
            radius: floatingBg.currentRadius
            active: (widget ? widget.enableShadow : true) && HyprlandService.hyprShadow
            opacity: Math.min(1, Math.max(0, root.bounceProgress))
        }

        Shape {
            id: floatingBg

            readonly property int safeWidth: {
                let w = Math.round(parent.width);
                return (w % 2 === 0) ? w : (w + 1);
            }
            readonly property int safeHeight: Math.round(parent.height)
            readonly property real currentRadius: windowRadius

            anchors.centerIn: parent
            width: safeWidth
            height: safeHeight

            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillColor: root.backgroundColor

                PathSvg {
                    path: {
                        let w = floatingBg.width;
                        let h = floatingBg.height;
                        let r = floatingBg.currentRadius;
                        if (w <= 0 || h <= 0)
                            return "";

                        r = Math.max(0, Math.min(r, Math.min(w / 2, h / 2)));
                        if (r <= 0.5)
                            return `M 0 0 L ${w} 0 L ${w} ${h} L 0 ${h} Z`;

                        let k = r * 0.552285;
                        return `M ${r} 0 L ${w - r} 0 C ${w - r + k} 0, ${w} ${r - k}, ${w} ${r} L ${w} ${h - r} C ${w} ${h - r + k}, ${w - r + k} ${h}, ${w - r} ${h} L ${r} ${h} C ${r - k} ${h}, 0 ${h - r + k}, 0 ${h - r} L 0 ${r} C 0 ${r - k}, ${r - k} 0, ${r} 0 Z`;
                    }
                }

            }

        }

        // Prevent clicks on the container from reaching the dismiss area
        MouseArea {
            anchors.fill: parent
        }

        Item {
            id: contentLayoutContainer

            anchors.fill: parent
            anchors.margins: contentPadding
            clip: true
        }

    }

}
