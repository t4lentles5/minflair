import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import qs.Core
import qs.Core.Components
import qs.Core.Services

Item {
    id: root

    property string popupId: ""
    property bool isOpen: false
    readonly property bool isConvex: SettingsService.barConvexMode
    property int cornerRadius: root.isConvex ? Constants.size2Xl : Constants.sizeLg * 2
    property int contentPadding: Constants.sizeLg
    default property alias content: innerLayout.data
    property int preferredHeight: 0
    property int preferredWidth: 0
    property int contentWidth: -1
    property int contentHeight: -1
    readonly property int topPadding: Constants.sizeLg
    readonly property int bottomPadding: root.isConvex ? (Constants.sizeLg + cornerRadius) : Constants.sizeLg
    readonly property int leftPadding: root.isConvex ? (Constants.sizeLg + cornerRadius) : Constants.sizeLg
    readonly property int rightPadding: Constants.sizeLg
    readonly property int verticalPadding: topPadding
    readonly property int popupWidth: (contentWidth > 0 ? contentWidth : (innerLayout.children.length > 0 && innerLayout.children[0].implicitWidth > 0 ? innerLayout.children[0].implicitWidth : innerLayout.implicitWidth)) + leftPadding + rightPadding
    readonly property int popupHeight: (contentHeight > 0 ? contentHeight : (innerLayout.children.length > 0 && innerLayout.children[0].implicitHeight > 0 ? innerLayout.children[0].implicitHeight : innerLayout.implicitHeight)) + topPadding + bottomPadding
    property int targetHeight: preferredHeight > 0 ? preferredHeight : popupHeight
    property real smoothHeight: targetHeight
    property int targetWidth: preferredWidth > 0 ? preferredWidth : popupWidth
    property real smoothWidth: targetWidth
    property int animationDuration: HyprlandService.enableAnimations ? Constants.animSlow : 0
    readonly property int closeDuration: HyprlandService.enableAnimations ? Constants.animNormal : 0
    readonly property int fadeDuration: HyprlandService.enableAnimations ? Constants.animNormal : 0
    property color backgroundColor: Theme.bg
    property bool animateHeight: false
    property bool positionAtRight: true
    property bool _visible: false
    readonly property int verticalOffset: Constants.sizeLg
    readonly property int overshootHeadroom: 20
    property real diagProgress: root.isOpen ? 1 : 0
    property bool hasBeenHovered: false

    signal popupOpened()
    signal popupClosed()
    signal fullyClosed()

    implicitWidth: smoothWidth + 2 * overshootHeadroom
    implicitHeight: smoothHeight + verticalOffset + 100
    visible: _visible
    onIsOpenChanged: {
        if (popupId === "")
            return ;

        if (isOpen) {
            _visible = true;
            root.popupOpened();
            hasBeenHovered = containerHoverHandler.hovered;
        } else {
            hasBeenHovered = false;
            autoCloseTimer.stop();
            root.popupClosed();
            if (!HyprlandService.enableAnimations) {
                _visible = false;
                root.fullyClosed();
            }
        }
    }
    onEnabledChanged: {
        if (!enabled && isOpen)
            isOpen = false;

    }

    Timer {
        id: autoCloseTimer

        interval: Constants.animExpressive
        repeat: false
        onTriggered: {
            hyprpickerCheck.running = true;
        }
    }

    Process {
        id: hyprpickerCheck

        command: ["pgrep", "-f", "hyprpicker"]
        onExited: (code) => {
            if (code === 0)
                autoCloseTimer.start();
            else
                hyprlandCheck.running = true;
        }
    }

    Process {
        id: hyprlandCheck

        command: ["pgrep", "-f", "screenshot.sh"]
        onExited: (code) => {
            if (code === 0)
                autoCloseTimer.start();
            else
                root.isOpen = false;
        }
    }

    Item {
        id: animContainer

        readonly property real targetH: smoothHeight
        readonly property real targetW: smoothWidth
        readonly property real currentWidth: root.isConvex ? Math.max(targetW * Math.max(0, root.diagProgress), 0.01) : targetW
        readonly property real currentHeight: root.isConvex ? Math.max(targetH * Math.max(0, root.diagProgress), 0.01) : targetH

        width: currentWidth
        height: currentHeight
        clip: root.isConvex
        x: root.isConvex ? (2 * root.overshootHeadroom + smoothWidth - currentWidth) : root.overshootHeadroom
        y: root.isConvex ? 0 : 8 - (16 * (1 - Math.max(0, root.diagProgress)))
        opacity: 1
        scale: root.isConvex ? 1 : Math.max(0, root.diagProgress)
        transformOrigin: root.isConvex ? Item.TopRight : Item.Top

        HoverHandler {
            id: containerHoverHandler

            onHoveredChanged: {
                if (hovered) {
                    root.hasBeenHovered = true;
                    autoCloseTimer.stop();
                } else if (root.isOpen && root.hasBeenHovered) {
                    autoCloseTimer.start();
                }
            }
        }

        MouseArea {
            anchors.fill: parent
        }

        FramedShape {
            id: bg

            width: parent.width
            height: parent.height
            x: 0
            y: 0
            color: root.backgroundColor
            cornerRadius: root.cornerRadius
            positionAtRight: true
            isConvex: root.isConvex
            visible: root.isConvex
            enableShadow: false
        }

        Item {
            id: innerLayout

            x: root.isConvex ? (animContainer.width - smoothWidth + root.leftPadding) : root.leftPadding
            y: root.topPadding
            width: smoothWidth - root.leftPadding - root.rightPadding
            height: smoothHeight - root.topPadding - root.bottomPadding
            opacity: 1
        }

    }

    Behavior on smoothHeight {
        enabled: HyprlandService.enableAnimations && root.animateHeight

        NumberAnimation {
            duration: root.animationDuration
            easing.type: Easing.OutExpo
        }

    }

    Behavior on smoothWidth {
        enabled: HyprlandService.enableAnimations && root.isOpen

        NumberAnimation {
            duration: Constants.animFast
            easing.type: Easing.OutExpo
        }

    }

    Behavior on diagProgress {
        enabled: HyprlandService.enableAnimations

        NumberAnimation {
            id: diagAnim

            duration: root.isOpen ? root.animationDuration : root.closeDuration
            easing.type: {
                if (root.isConvex)
                    return root.isOpen ? Easing.OutCubic : Easing.InCubic;
                else
                    return root.isOpen ? Easing.OutBack : Easing.InCubic;
            }
            easing.overshoot: (!root.isConvex && root.isOpen) ? 1.15 : 0
            onRunningChanged: {
                if (!running && !root.isOpen) {
                    root._visible = false;
                    root.fullyClosed();
                }
            }
        }

    }

}
