import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import qs.Core
import qs.Core.Components
import qs.Core.Services

Item {
    id: root

    property string widgetId: ""
    property bool isOpen: false
    property bool positionAtLeft: false
    property int cornerRadius: Constants.sizeLg * 2
    property int contentPadding: Constants.sizeLg
    property int flareHeight: Constants.size2Xl + 4
    property int flareWidth: Constants.size2Xl + 4
    property bool alignTop: false
    property int topOffset: (SettingsService.barStyle === "convex" ? 48 : 24)
    readonly property int verticalPadding: flareHeight + contentPadding
    default property alias content: innerLayout.data
    property int _screenHeight: 1080
    property int _screenWidth: 1920
    property int preferredHeight: 0
    property int preferredWidth: 0
    property int contentWidth: -1
    property int contentHeight: -1
    readonly property int widgetWidth: (contentWidth > 0 ? contentWidth : innerLayout.implicitWidth) + contentPadding * 2
    readonly property int widgetHeight: (contentHeight > 0 ? contentHeight : innerLayout.implicitHeight) + (root.verticalPadding * 2)
    property int targetHeight: preferredHeight > 0 ? preferredHeight : (_screenHeight > 0 ? Math.min(widgetHeight, _screenHeight - 120) : widgetHeight)
    property real smoothHeight: targetHeight
    property int targetWidth: preferredWidth > 0 ? preferredWidth : widgetWidth
    property real smoothWidth: targetWidth
    property int animationDuration: HyprlandService.enableAnimations ? Constants.animExpressive : 0
    readonly property int closeDuration: HyprlandService.enableAnimations ? Constants.animNormal : 0
    property color backgroundColor: Theme.bg
    property bool animateHeight: false
    property bool _visible: false
    property real bounceProgress: root.isOpen ? 1 : 0

    signal widgetOpened()
    signal widgetClosed()
    signal fullyClosed()

    function close() {
        if (widgetId !== "")
            AppState.closeWidget(widgetId);
        else
            root.isOpen = false;
    }

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
        if (isOpen) {
            closeDelayTimer.stop();
            _visible = true;
            root.widgetOpened();
        } else {
            root.widgetClosed();
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
        acceptedButtons: Qt.AllButtons
        enabled: root.isOpen
        onClicked: root.close()
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

            readonly property real openX: root.positionAtLeft ? 0 : (_screenWidth - smoothWidth)
            readonly property real currentWidth: Math.max(smoothWidth * bounceProgress, 0.01)

            width: Math.round(currentWidth)
            height: Math.round(smoothHeight)
            clip: true
            x: Math.round(root.positionAtLeft ? openX : (openX + smoothWidth - currentWidth))
            y: root.alignTop ? Math.round(root.topOffset) : Math.round((_screenHeight - targetHeight) / 2)

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
            }

            Shape {
                id: bg

                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                layer.enabled: true
                layer.smooth: true
                layer.samples: 4

                ShapePath {
                    strokeWidth: 0
                    strokeColor: "transparent"
                    fillColor: root.backgroundColor

                    PathSvg {
                        path: {
                            let w = bg.width;
                            let h = bg.height;
                            let tb = (SettingsService.barStyle === "convex") ? 8 : 0;
                            if (w <= tb || h <= 0)
                                return "";

                            let maxFw = Math.min(root.flareWidth, Math.max(0, (w - tb) * 0.35));
                            let maxFh = Math.min(root.flareHeight, Math.max(0, h * 0.25));
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
                        }
                    }

                }

            }

            ColumnLayout {
                id: innerLayout

                x: root.positionAtLeft ? root.contentPadding : (animContainer.width - smoothWidth + root.contentPadding)
                y: root.verticalPadding
                width: smoothWidth - root.contentPadding * 2
                height: smoothHeight - (root.verticalPadding * 2)
            }

            Behavior on y {
                enabled: HyprlandService.enableAnimations && root.isOpen && root.bounceProgress >= 0.99

                NumberAnimation {
                    duration: Constants.animSlow
                    easing.type: Easing.OutQuint
                }

            }

        }

    }

    Behavior on bounceProgress {
        enabled: HyprlandService.enableAnimations

        NumberAnimation {
            duration: root.isOpen ? root.animationDuration : root.closeDuration
            easing.type: root.isOpen ? Easing.OutQuint : Easing.OutCubic
            easing.overshoot: 0
            onRunningChanged: {
                if (!running && !root.isOpen) {
                    closeDelayTimer.stop();
                    root._visible = false;
                    root.fullyClosed();
                }
            }
        }

    }

    Behavior on smoothHeight {
        enabled: HyprlandService.enableAnimations && root.isOpen && root.bounceProgress >= 0.99

        NumberAnimation {
            duration: Constants.animSlow
            easing.type: Easing.OutQuint
        }

    }

    Behavior on smoothWidth {
        enabled: HyprlandService.enableAnimations && root.isOpen && root.bounceProgress >= 0.99

        NumberAnimation {
            duration: Constants.animSlow
            easing.type: Easing.OutQuint
        }

    }

}
