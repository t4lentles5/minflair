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
    property alias contentSlot: contentLayoutContainer
    property alias container: mainContainer
    property bool isHandover: false
    property bool isClosing: false
    readonly property real bounceProgress: widget ? widget.bounceProgress : 0
    readonly property real openProgress: widget ? widget.openProgress : 0

    anchors.fill: parent

    Item {
        id: mainContainer

        readonly property real targetOverlayWidth: preferredWidth + windowRadius * 2
        readonly property real targetOverlayHeight: preferredHeight
        readonly property real openY: root.height - preferredHeight - 8

        width: targetOverlayWidth
        height: Math.max(targetOverlayHeight * bounceProgress, 0.01)
        anchors.horizontalCenter: parent.horizontalCenter
        transformOrigin: Item.Bottom
        y: Math.round(openY + targetOverlayHeight - height)

        Shape {
            id: bg

            property color shapeColor: root.backgroundColor
            readonly property real rx: windowRadius
            readonly property real ry: Math.min(windowRadius, h / 2.1)
            readonly property real w: width
            readonly property real h: height

            anchors.fill: parent
            layer.enabled: HyprlandService.hyprShadow

            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillColor: bg.shapeColor
                startX: 0
                startY: bg.h

                PathArc {
                    x: bg.rx
                    y: bg.h - bg.ry
                    radiusX: bg.rx
                    radiusY: bg.ry
                    direction: PathArc.Counterclockwise
                }

                PathLine {
                    x: bg.rx
                    y: bg.ry
                }

                PathQuad {
                    x: 2 * bg.rx
                    y: 0
                    controlX: bg.rx
                    controlY: 0
                }

                PathLine {
                    x: bg.w - 2 * bg.rx
                    y: 0
                }

                PathQuad {
                    x: bg.w - bg.rx
                    y: bg.ry
                    controlX: bg.w - bg.rx
                    controlY: 0
                }

                PathLine {
                    x: bg.w - bg.rx
                    y: bg.h - bg.ry
                }

                PathArc {
                    x: bg.w
                    y: bg.h
                    radiusX: bg.rx
                    radiusY: bg.ry
                    direction: PathArc.Counterclockwise
                }

                PathLine {
                    x: 0
                    y: bg.h
                }

            }

            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowBlur: 1
                blurMax: 16
                shadowColor: Qt.alpha(Theme.shadow, 0.75)
                shadowVerticalOffset: 0
                shadowHorizontalOffset: 0
            }

        }

        // Prevent clicks on the container from reaching the dismiss area
        MouseArea {
            anchors.fill: parent
        }

        Item {
            id: contentLayoutContainer

            anchors.fill: parent
            anchors.leftMargin: windowRadius + contentPadding
            anchors.rightMargin: windowRadius + contentPadding
            anchors.topMargin: contentPadding
            anchors.bottomMargin: (contentPadding > 0) ? 8 : 0
            clip: true
            opacity: openProgress
            transformOrigin: Item.Bottom
        }

    }

}
