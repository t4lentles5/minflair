import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import qs.Core
import qs.Core.Components
import qs.Core.Services

Item {
    id: root

    property string popupId: ""
    property bool isOpen: false
    readonly property bool isFramed: SettingsService.barFramedMode
    readonly property bool isConvex: SettingsService.barConvexMode
    property bool positionAtLeft: false
    property int cornerRadius: Constants.sizeLg * 2
    property int contentPadding: Constants.sizeLg
    property int notchFlareHeight: 28
    property int notchFlareWidth: 28
    property int notchVerticalPadding: notchFlareHeight + contentPadding
    default property alias content: innerLayout.data
    property int _screenHeight: 1080
    property int _screenWidth: 1920
    property int preferredHeight: 0
    property int preferredWidth: 0
    property int contentWidth: -1
    property int contentHeight: -1
    readonly property int popupWidth: (contentWidth > 0 ? contentWidth : innerLayout.implicitWidth) + contentPadding * 2
    readonly property int popupHeight: (contentHeight > 0 ? contentHeight : innerLayout.implicitHeight) + (root.isConvex ? (root.notchVerticalPadding * 2) : (contentPadding * 2))
    property int targetHeight: root.isFramed ? (_screenHeight > 0 ? _screenHeight - 56 : popupHeight) : (root.isConvex ? (preferredHeight > 0 ? preferredHeight : (_screenHeight > 0 ? Math.min(popupHeight, _screenHeight - 120) : popupHeight)) : Math.min(preferredHeight > 0 ? preferredHeight : popupHeight, _screenHeight > 0 ? _screenHeight - 72 : popupHeight))
    property real smoothHeight: targetHeight
    property int targetWidth: preferredWidth > 0 ? preferredWidth : popupWidth
    property real smoothWidth: targetWidth
    property int animationDuration: HyprlandService.enableAnimations ? Constants.animSlow : 0
    readonly property int closeDuration: HyprlandService.enableAnimations ? Constants.animNormal : 0
    readonly property int fadeDuration: HyprlandService.enableAnimations ? Constants.animNormal : 0
    property color backgroundColor: Theme.bg
    property bool animateHeight: false
    property bool _visible: false
    readonly property int overshootHeadroom: 20
    property real openProgress: root.isOpen ? 1 : 0
    property real bounceProgress: root.isOpen ? 1 : 0

    signal popupOpened()
    signal popupClosed()
    signal fullyClosed()

    onWidthChanged: {
        if (width > 0)
            _screenWidth = width;

    }
    onHeightChanged: {
        if (height > 0)
            _screenHeight = height;

    }
    visible: _visible
    onIsOpenChanged: {
        if (popupId === "")
            return ;

        if (isOpen) {
            if (!root.isConvex && AppState.activePopup !== popupId)
                AppState.activePopup = popupId;

            closeDelayTimer.stop();
            _visible = true;
            root.popupOpened();
        } else {
            if (!root.isConvex && AppState.activePopup === popupId)
                AppState.activePopup = "";

            root.popupClosed();
            if (!HyprlandService.enableAnimations) {
                root._visible = false;
                root.fullyClosed();
            } else {
                closeDelayTimer.start();
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.isOpen
        onClicked: root.isOpen = false
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

    Item {
        anchors.fill: parent
        clip: true

        Item {
            id: animContainer

            readonly property real closedX: root.positionAtLeft ? (-smoothWidth - 20) : (_screenWidth > 0 ? _screenWidth + 20 : 3000)
            readonly property real openX: root.positionAtLeft ? (root.isConvex ? 0 : (root.isFramed ? 8 : 8)) : (root.isConvex ? (_screenWidth - smoothWidth) : (root.isFramed ? (_screenWidth - smoothWidth - 8) : (_screenWidth - smoothWidth - 8)))
            readonly property real currentWidth: (root.isFramed || root.isConvex) ? Math.max(smoothWidth * bounceProgress, 0.01) : smoothWidth
            readonly property real cornerOffset: (!root.positionAtLeft && root.isFramed) ? Constants.size4Xl : 0

            width: Math.round(currentWidth + cornerOffset)
            height: Math.round(smoothHeight)
            clip: false
            x: Math.round(root.positionAtLeft ? ((root.isFramed || root.isConvex) ? openX : (closedX + (openX - closedX) * bounceProgress)) : ((root.isFramed || root.isConvex) ? (openX + smoothWidth - currentWidth) : (closedX + (openX - closedX) * bounceProgress)) - cornerOffset)
            y: root.isFramed ? 48 : (root.isConvex ? Math.round((_screenHeight - smoothHeight) / 2) : 64)
            opacity: (root.isFramed || root.isConvex) ? 1 : openProgress

            MouseArea {
                anchors.fill: parent
            }

            ThemedShadow {
                anchors.fill: bg
                radius: root.cornerRadius
                active: !root.isFramed && !root.isConvex
            }

            Shape {
                id: bg

                x: 0
                y: 0
                width: parent.width
                height: parent.height
                layer.enabled: false

                ShapePath {
                    strokeWidth: 0
                    strokeColor: "transparent"
                    fillColor: root.backgroundColor

                    PathSvg {
                        path: {
                            let w = bg.width;
                            let h = bg.height;
                            let fy = Constants.size4Xl;
                            let fx = Math.min(Constants.size4Xl, w / 2.1);
                            if (root.isFramed) {
                                if (root.positionAtLeft) {
                                    let mainPath = `M ${w - fx} 0 L ${fx} 0 A ${fx} ${fy} 0 0 0 0 ${fy} L 0 ${h - fy} A ${fx} ${fy} 0 0 0 ${fx} ${h} L ${w - fx} ${h} `;
                                    let bFillet = `L ${w} ${h} A ${fx} ${fy} 0 0 1 ${w - fx} ${h - fy} `;
                                    let tFillet = `L ${w - fx} ${fy} A ${fx} ${fy} 0 0 1 ${w} 0 Z`;
                                    return mainPath + bFillet + tFillet;
                                } else {
                                    let mainPath = `M ${fx} 0 L ${w - fx} 0 A ${fx} ${fy} 0 0 1 ${w} ${fy} L ${w} ${h - fy} A ${fx} ${fy} 0 0 1 ${w - fx} ${h} L ${fx} ${h} `;
                                    let bFillet = `L 0 ${h} A ${fx} ${fy} 0 0 0 ${fx} ${h - fy} `;
                                    let tFillet = `L ${fx} ${fy} A ${fx} ${fy} 0 0 0 0 0 Z`;
                                    return mainPath + bFillet + tFillet;
                                }
                            } else if (root.isConvex) {
                                let tb = 8;
                                if (w <= tb || h <= 0)
                                    return "";

                                let maxFw = Math.min(root.notchFlareWidth, Math.max(0, (w - tb) * 0.35));
                                let maxFh = Math.min(root.notchFlareHeight, Math.max(0, h * 0.25));
                                let maxR = Math.min(root.cornerRadius, Math.max(0, (w - tb - maxFw) * 0.5));
                                let k = maxR * 0.552285;
                                let kf = maxFw * 0.552285;
                                let kh = maxFh * 0.552285;
                                if (root.positionAtLeft) {
                                    let p = `M ${tb} 0 `;
                                    p += `C ${tb} ${kh}, ${tb + kf} ${maxFh}, ${tb + maxFw} ${maxFh} `;
                                    p += `L ${w - maxR} ${maxFh} `;
                                    p += `C ${w - maxR + k} ${maxFh}, ${w} ${maxFh + maxR - k}, ${w} ${maxFh + maxR} `;
                                    p += `L ${w} ${h - maxFh - maxR} `;
                                    p += `C ${w} ${h - maxFh - maxR + k}, ${w - maxR + k} ${h - maxFh}, ${w - maxR} ${h - maxFh} `;
                                    p += `L ${tb + maxFw} ${h - maxFh} `;
                                    p += `C ${tb + kf} ${h - maxFh}, ${tb} ${h - kh}, ${tb} ${h} `;
                                    p += `Z`;
                                    return p;
                                } else {
                                    let p = `M ${w - tb} 0 `;
                                    p += `C ${w - tb} ${kh}, ${w - tb - kf} ${maxFh}, ${w - tb - maxFw} ${maxFh} `;
                                    p += `L ${maxR} ${maxFh} `;
                                    p += `C ${maxR - k} ${maxFh}, 0 ${maxFh + maxR - k}, 0 ${maxFh + maxR} `;
                                    p += `L 0 ${h - maxFh - maxR} `;
                                    p += `C 0 ${h - maxFh - maxR + k}, ${maxR - k} ${h - maxFh}, ${maxR} ${h - maxFh} `;
                                    p += `L ${w - tb - maxFw} ${h - maxFh} `;
                                    p += `C ${w - tb - kf} ${h - maxFh}, ${w - tb} ${h - kh}, ${w - tb} ${h} `;
                                    p += `Z`;
                                    return p;
                                }
                            } else {
                                let r = root.cornerRadius;
                                if (r <= 0.5)
                                    return `M 0 0 L ${w} 0 L ${w} ${h} L 0 ${h} Z`;

                                r = Math.max(0, Math.min(r, Math.min(w / 2, h / 2)));
                                let k = r * 0.552285;
                                return `M ${r} 0 ` + `L ${w - r} 0 ` + `C ${w - r + k} 0, ${w} ${r - k}, ${w} ${r} ` + `L ${w} ${h - r} ` + `C ${w} ${h - r + k}, ${w - r + k} ${h}, ${w - r} ${h} ` + `L ${r} ${h} ` + `C ${r - k} ${h}, 0 ${h - r + k}, 0 ${h - r} ` + `L 0 ${r} ` + `C 0 ${r - k}, ${r - k} 0, ${r} 0 Z`;
                            }
                        }
                    }

                }

            }

            ColumnLayout {
                id: innerLayout

                x: root.positionAtLeft ? root.contentPadding : (root.contentPadding + animContainer.cornerOffset)
                y: root.isConvex ? root.notchVerticalPadding : root.contentPadding
                width: smoothWidth - root.contentPadding * 2
                height: smoothHeight - (root.isConvex ? (root.notchVerticalPadding * 2) : (root.contentPadding * 2))
                opacity: (root.isFramed || root.isConvex) ? root.openProgress : 1
            }

        }

    }

    Behavior on openProgress {
        enabled: HyprlandService.enableAnimations

        NumberAnimation {
            id: openProgressAnim

            duration: root.isOpen ? root.fadeDuration : root.closeDuration
            easing.type: root.isOpen ? Easing.OutCubic : Easing.InCubic
            onRunningChanged: {
                if (!running && !root.isOpen) {
                    root._visible = false;
                    root.fullyClosed();
                }
            }
        }

    }

    Behavior on bounceProgress {
        enabled: HyprlandService.enableAnimations

        NumberAnimation {
            duration: root.isOpen ? root.animationDuration : root.closeDuration
            easing.type: {
                if (root.isFramed || root.isConvex)
                    return root.isOpen ? Easing.OutCubic : Easing.InCubic;
                else
                    return root.isOpen ? Easing.OutBack : Easing.InCubic;
            }
            easing.overshoot: (!root.isFramed && !root.isConvex && root.isOpen) ? 1.15 : 0
        }

    }

    Behavior on smoothHeight {
        enabled: HyprlandService.enableAnimations && root.isOpen

        NumberAnimation {
            duration: root.animationDuration
            easing.type: Easing.OutExpo
        }

    }

    Behavior on smoothWidth {
        enabled: HyprlandService.enableAnimations && root.isOpen

        NumberAnimation {
            duration: root.animationDuration
            easing.type: Easing.OutExpo
        }

    }

}
