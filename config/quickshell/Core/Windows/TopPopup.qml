import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Effects
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
    readonly property bool isFramed: SettingsService.barFramedMode
    readonly property bool isMinflair: SettingsService.barMinflairMode
    readonly property bool isNotch: SettingsService.barNotchMode
    readonly property bool isConvex: SettingsService.barConvexMode
    readonly property bool isAttachedToTop: isFramed || isMinflair || (isConvex && popupId === "music")
    property int cornerRadius: Constants.sizeLg * 2
    property int contentPadding: Constants.sizeLg
    default property alias content: innerLayout.data
    property int preferredHeight: 0
    property int preferredWidth: 0
    property int contentWidth: -1
    property int contentHeight: -1
    readonly property int horizontalPadding: root.isAttachedToTop ? (contentPadding + cornerRadius) : 16
    readonly property int verticalPadding: root.isAttachedToTop ? contentPadding : 16
    readonly property int popupWidth: (contentWidth > 0 ? contentWidth : (innerLayout.children.length > 0 && innerLayout.children[0].implicitWidth > 0 ? innerLayout.children[0].implicitWidth : innerLayout.implicitWidth)) + horizontalPadding * 2
    readonly property int popupHeight: (contentHeight > 0 ? contentHeight : (innerLayout.children.length > 0 && innerLayout.children[0].implicitHeight > 0 ? innerLayout.children[0].implicitHeight : innerLayout.implicitHeight)) + verticalPadding * 2
    property int targetHeight: preferredHeight > 0 ? preferredHeight : popupHeight
    property real smoothHeight: targetHeight
    property int targetWidth: preferredWidth > 0 ? preferredWidth : popupWidth
    property real smoothWidth: targetWidth
    property int animationDuration: HyprlandService.enableAnimations ? Constants.animSlow : 0
    readonly property int closeDuration: HyprlandService.enableAnimations ? Constants.animNormal : 0
    readonly property int fadeDuration: HyprlandService.enableAnimations ? Constants.animNormal : 0
    property color backgroundColor: Theme.bg
    property bool animateHeight: false
    property bool positionAtRight: false
    property bool _visible: false
    readonly property int verticalOffset: Constants.sizeLg
    readonly property int overshootHeadroom: 20
    property real bounceProgress: root.isOpen ? 1 : 0
    property real openProgress: root.isOpen ? 1 : 0
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
            if (AppState.activePopup !== popupId)
                AppState.activePopup = popupId;

            closeDelayTimer.stop();
            _visible = true;
            root.popupOpened();
            hasBeenHovered = containerHoverHandler.hovered;
        } else {
            if (AppState.activePopup === popupId)
                AppState.activePopup = "";

            hasBeenHovered = false;
            autoCloseTimer.stop();
            root.popupClosed();
            if (!HyprlandService.enableAnimations) {
                _visible = false;
                root.fullyClosed();
            } else {
                closeDelayTimer.start();
            }
        }
    }
    onEnabledChanged: {
        if (!enabled && isOpen)
            isOpen = false;

    }

    Timer {
        id: closeDelayTimer

        interval: root.closeDuration + 50
        repeat: false
        onTriggered: {
            if (!root.isOpen) {
                root._visible = false;
                root.fullyClosed();
            }
        }
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

        readonly property real targetH: (root.isFramed && root.positionAtRight) ? (smoothHeight + root.cornerRadius) : smoothHeight
        readonly property real currentHeight: root.isAttachedToTop ? Math.max(targetH * Math.max(0, bounceProgress), 0.01) : smoothHeight

        width: smoothWidth
        height: root.isAttachedToTop ? currentHeight : smoothHeight
        clip: root.isAttachedToTop
        x: root.positionAtRight ? 2 * root.overshootHeadroom + smoothWidth - width : root.overshootHeadroom
        y: root.isAttachedToTop ? 0 : (root.isConvex ? (0 - 10 * (1 - Math.max(0, bounceProgress))) : 8 - (16 * (1 - Math.max(0, bounceProgress))))
        opacity: root.isAttachedToTop ? 1 : Math.min(1, Math.max(0, bounceProgress / 0.55))
        scale: root.isAttachedToTop ? 1 : (0.93 + 0.07 * Math.max(0, bounceProgress))
        transformOrigin: root.positionAtRight ? Item.TopRight : Item.Top

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
            positionAtRight: root.positionAtRight
            isFramed: true
            enableShadow: false
            visible: root.isAttachedToTop && !notchBg.visible
        }

        NotchShape {
            id: notchBg

            anchors.fill: parent
            color: root.backgroundColor
            flareWidth: 18
            flareHeight: 16
            topBezel: root.isConvex ? 8 : 0
            bottomRadius: root.cornerRadius
            visible: (root.isConvex && root.popupId === "music")
        }

        ThemedShadow {
            anchors.fill: floatingBg
            radius: floatingBg.currentRadius
            active: !root.isAttachedToTop
        }

        Shape {
            id: floatingBg

            readonly property int safeWidth: {
                let w = Math.round(parent.width);
                return (w % 2 === 0) ? w : (w + 1);
            }
            readonly property int safeHeight: Math.round(parent.height)
            readonly property real currentRadius: root.cornerRadius

            anchors.centerIn: parent
            width: safeWidth
            height: safeHeight
            visible: !root.isAttachedToTop

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
                        return `M ${r} 0 ` + `L ${w - r} 0 ` + `C ${w - r + k} 0, ${w} ${r - k}, ${w} ${r} ` + `L ${w} ${h - r} ` + `C ${w} ${h - r + k}, ${w - r + k} ${h}, ${w - r} ${h} ` + `L ${r} ${h} ` + `C ${r - k} ${h}, 0 ${h - r + k}, 0 ${h - r} ` + `L 0 ${r} ` + `C 0 ${r - k}, ${r - k} 0, ${r} 0 Z`;
                    }
                }

            }

        }

        Item {
            id: innerLayout

            x: root.positionAtRight ? animContainer.width - width - root.horizontalPadding : root.horizontalPadding
            y: root.verticalPadding
            width: smoothWidth - root.horizontalPadding * 2
            height: smoothHeight - root.verticalPadding * 2
            opacity: root.isAttachedToTop ? root.openProgress : 1
        }

    }

    Behavior on smoothHeight {
        enabled: HyprlandService.enableAnimations && root.animateHeight

        NumberAnimation {
            duration: Constants.animNormal
            easing.type: Easing.OutCubic
        }

    }

    Behavior on smoothWidth {
        enabled: HyprlandService.enableAnimations && root.isOpen

        NumberAnimation {
            duration: Constants.animNormal
            easing.type: Easing.OutCubic
        }

    }

    Behavior on openProgress {
        enabled: HyprlandService.enableAnimations

        NumberAnimation {
            id: openProgressAnim

            duration: root.isOpen ? root.fadeDuration : root.closeDuration
            easing.type: root.isOpen ? Easing.OutCubic : Easing.InCubic
        }

    }

    Behavior on bounceProgress {
        enabled: HyprlandService.enableAnimations

        NumberAnimation {
            id: bounceAnim

            duration: root.isOpen ? (root.isConvex ? Constants.animNormal : root.animationDuration) : root.closeDuration
            easing.type: {
                if (root.isAttachedToTop)
                    return root.isOpen ? Easing.OutCubic : Easing.InCubic;
                else if (root.isConvex)
                    return root.isOpen ? Easing.OutQuint : Easing.InCubic;
                else
                    return root.isOpen ? Easing.OutBack : Easing.InCubic;
            }
            easing.overshoot: (!root.isAttachedToTop && root.isOpen && !root.isConvex) ? 1.15 : 0
            onRunningChanged: {
                if (!running && !root.isOpen) {
                    closeDelayTimer.stop();
                    root._visible = false;
                    root.fullyClosed();
                }
            }
        }

    }

}
