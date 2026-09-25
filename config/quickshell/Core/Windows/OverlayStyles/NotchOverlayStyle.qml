import QtQuick
import qs.Core
import qs.Core.Components

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
    readonly property int flareWidth: widget ? widget.notchFlareWidth : 18
    readonly property int flareHeight: widget ? widget.notchFlareHeight : 16
    readonly property int sidePadding: widget ? widget.notchSidePadding : 0
    readonly property int bottomPadding: widget ? widget.notchBottomPadding : 0
    readonly property int totalHorizPadding: (flareWidth + sidePadding) * 2

    anchors.fill: parent

    Item {
        id: mainContainer

        readonly property real targetOverlayWidth: preferredWidth + totalHorizPadding
        readonly property real targetOverlayHeight: preferredHeight + bottomPadding
        readonly property real openY: root.height - targetOverlayHeight

        width: targetOverlayWidth
        height: Math.max(targetOverlayHeight * bounceProgress, 0.01)
        anchors.horizontalCenter: parent.horizontalCenter
        transformOrigin: Item.Bottom
        y: Math.round(openY + targetOverlayHeight - height)

        NotchShape {
            id: bottomNotchBg

            anchors.fill: parent
            color: root.backgroundColor
            flareWidth: root.flareWidth
            flareHeight: root.flareHeight
            topRadius: (windowRadius > 0 && windowRadius <= 12) ? windowRadius : Constants.sizeSm
            inverted: true
        }

        // Prevent clicks on the container from reaching the dismiss area
        MouseArea {
            anchors.fill: parent
        }

        Item {
            id: contentLayoutContainer

            anchors.fill: parent
            anchors.leftMargin: flareWidth + sidePadding
            anchors.rightMargin: flareWidth + sidePadding
            anchors.topMargin: 0
            anchors.bottomMargin: bottomPadding
            clip: true
            opacity: openProgress
            transformOrigin: Item.Bottom
        }

    }

}
