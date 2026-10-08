import QtQuick
import qs.Core
import qs.Core.Components
import qs.Core.Services

Item {
    id: cropFrameRoot

    required property var previewRoot
    required property var wallCanvas
    readonly property alias cropFrame: cropFrame

    anchors.fill: parent

    // 4 Darkening Overlays outside the framing box (visible in Crop mode when aspect ratios differ)
    // Left overlay
    Rectangle {
        visible: previewRoot.isCropMode && (previewRoot.isWider || previewRoot.isTaller)
        x: 0
        y: 0
        width: cropFrame.x
        height: parent.height
        color: Theme.bg
        opacity: 0.7
    }

    // Right overlay
    Rectangle {
        visible: previewRoot.isCropMode && (previewRoot.isWider || previewRoot.isTaller)
        x: cropFrame.x + cropFrame.width
        y: 0
        width: Math.max(0, parent.width - (cropFrame.x + cropFrame.width))
        height: parent.height
        color: Theme.bg
        opacity: 0.7
    }

    // Top overlay
    Rectangle {
        visible: previewRoot.isCropMode && (previewRoot.isWider || previewRoot.isTaller)
        x: cropFrame.x
        y: 0
        width: cropFrame.width
        height: cropFrame.y
        color: Theme.bg
        opacity: 0.7
    }

    // Bottom overlay
    Rectangle {
        visible: previewRoot.isCropMode && (previewRoot.isWider || previewRoot.isTaller)
        x: cropFrame.x
        y: cropFrame.y + cropFrame.height
        width: cropFrame.width
        height: Math.max(0, parent.height - (cropFrame.y + cropFrame.height))
        color: Theme.bg
        opacity: 0.7
    }

    // The Selection Framing Box (representing the display screen area)
    Rectangle {
        id: cropFrame

        readonly property real frameTargetW: {
            if (!previewRoot.isCropMode)
                return wallCanvas.width;

            if (previewRoot.isWider)
                return Math.round(wallCanvas.height * previewRoot.screenRatio);

            return wallCanvas.width;
        }
        readonly property real frameTargetH: {
            if (!previewRoot.isCropMode)
                return wallCanvas.height;

            if (previewRoot.isTaller)
                return Math.round(wallCanvas.width / previewRoot.screenRatio);

            return wallCanvas.height;
        }
        readonly property real overflowX: Math.max(0, wallCanvas.width - frameTargetW)
        readonly property real overflowY: Math.max(0, wallCanvas.height - frameTargetH)
        readonly property real targetX: {
            if (!previewRoot.isCropMode || overflowX <= 0)
                return 0;

            let g = HyprlandService.wpCropGravity;
            if (g.includes("left"))
                return 0;

            if (g.includes("right"))
                return overflowX;

            return Math.round(overflowX / 2);
        }
        readonly property real targetY: {
            if (!previewRoot.isCropMode || overflowY <= 0)
                return 0;

            let g = HyprlandService.wpCropGravity;
            if (g.includes("top"))
                return 0;

            if (g.includes("bottom"))
                return overflowY;

            return Math.round(overflowY / 2);
        }

        x: targetX
        y: targetY
        width: frameTargetW
        height: frameTargetH
        radius: 6
        color: "transparent"
        border.width: Constants.size3Xs
        border.color: Theme.accent
        visible: previewRoot.isCropMode && (previewRoot.isWider || previewRoot.isTaller)

        // Screen label badge in top-left of the selection frame
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.margins: 6
            implicitHeight: 18
            implicitWidth: frameTagText.implicitWidth + 12
            radius: Constants.size2Xs
            color: Theme.accent

            ThemedText {
                id: frameTagText

                anchors.centerIn: parent
                text: "Display (" + previewRoot.getScreenRatioString() + ")"
                customSize: Constants.sizeXs
                font.bold: true
                color: Theme.bg
            }

        }

        Behavior on x {
            enabled: HyprlandService.enableAnimations

            NumberAnimation {
                duration: Constants.animNormal
                easing.type: Easing.OutCubic
            }

        }

        Behavior on y {
            enabled: HyprlandService.enableAnimations

            NumberAnimation {
                duration: Constants.animNormal
                easing.type: Easing.OutCubic
            }

        }

    }

}
