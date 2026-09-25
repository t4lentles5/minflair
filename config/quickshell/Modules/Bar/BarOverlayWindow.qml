import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.Core
import qs.Core.Services
import qs.Modules.Bar
import qs.Modules.Bar.Components

PanelWindow {
    id: root

    required property var notificationService
    required property PanelWindow barSurface
    property bool isShellReady: false
    property string activeBarStyle: SettingsService.barStyle
    property real currentBarMarginTop: barSurface.barMarginTop
    property real currentBarMarginSide: barSurface.barMarginSide
    property real currentBarHeight: barSurface.barHeight
    readonly property var styleData: BarStyleConfig.styleOf(activeBarStyle)
    readonly property bool hasFrame: styleData.hasFrame
    readonly property bool hasExpandableHost: styleData.hasExpandableHost
    readonly property bool usesFloatingPopups: styleData.usesFloatingPopups
    readonly property bool isCompact: styleData.isCompact
    readonly property QtObject activeHost: {
        if (SettingsService.barIslandMode || SettingsService.barNotchMode)
            return barStrip;

        if (SettingsService.barConvexMode)
            return barPopups.convexHost;

        return null;
    }
    readonly property bool needsFocus: (activeHost && activeHost.isOpen && activeHost.needsFocus)

    function triggerStyleSwitch() {
        if (!root.isShellReady || !SettingsService.settingsLoaded) {
            root.activeBarStyle = SettingsService.barStyle;
            return ;
        }
        let newStyle = SettingsService.barStyle;
        let oldStyle = root.activeBarStyle;
        if (oldStyle === newStyle) {
            let isFramedMode = newStyle === "framed" || newStyle === "convex";
            if (!isFramedMode && barStrip.opacity < 0.05) {
                barExitOnlyAnim.stop();
                barStyleSwitchAnim.stop();
                barEntranceAnim.stop();
                barStrip.opacity = 1;
                barTranslate.y = 0;
                barStrip.scale = 1;
            }
            return ;
        }
        let wasFramed = oldStyle === "framed" || oldStyle === "convex";
        let isFramed = newStyle === "framed" || newStyle === "convex";
        if (isFramed) {
            barStyleSwitchAnim.stop();
            barEntranceAnim.stop();
            barExitOnlyAnim.stop();
            barStrip.opacity = 1;
            barTranslate.y = 0;
            barStrip.scale = 1;
            root.activeBarStyle = newStyle;
        } else if (wasFramed) {
            barExitOnlyAnim.stop();
            barStyleSwitchAnim.stop();
            barEntranceAnim.stop();
            root.activeBarStyle = newStyle;
            root.currentBarMarginTop = Qt.binding(() => {
                return root.barSurface.barMarginTop;
            });
            root.currentBarMarginSide = Qt.binding(() => {
                return root.barSurface.barMarginSide;
            });
            root.currentBarHeight = Qt.binding(() => {
                return root.barSurface.barHeight;
            });
            barStrip.opacity = 1;
            barTranslate.y = 0;
            barStrip.scale = 1;
        } else {
            barExitOnlyAnim.stop();
            barEntranceAnim.stop();
            barStyleSwitchAnim.restart();
        }
    }

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: needsFocus ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"
    focusable: needsFocus
    Component.onCompleted: {
        activeBarStyle = SettingsService.barStyle;
    }
    onVisibleChanged: {
        if (visible) {
            let isFramedMode = SettingsService.barStyle === "framed" || SettingsService.barStyle === "convex";
            if (!isFramedMode) {
                root.activeBarStyle = SettingsService.barStyle;
                root.currentBarMarginTop = Qt.binding(() => {
                    return root.barSurface.barMarginTop;
                });
                root.currentBarMarginSide = Qt.binding(() => {
                    return root.barSurface.barMarginSide;
                });
                root.currentBarHeight = Qt.binding(() => {
                    return root.barSurface.barHeight;
                });
                barExitOnlyAnim.stop();
                barStyleSwitchAnim.stop();
                barEntranceAnim.stop();
                barStrip.opacity = 1;
                barTranslate.y = 0;
                barStrip.scale = 1;
            }
        }
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    Process {
        id: slurpCheckProcess

        command: ["sh", "-c", "pidof slurp"]
        onExited: {
            if (exitCode !== 0) {
                if (activeHost && activeHost.isOpen)
                    activeHost.close();

            }
        }
    }

    HyprlandFocusGrab {
        id: surfaceFocusGrab

        active: root.focusable
        windows: [root]
        onCleared: {
            slurpCheckProcess.running = true;
        }
    }

    ParallelAnimation {
        id: barExitOnlyAnim

        onFinished: {
            root.activeBarStyle = SettingsService.barStyle;
        }

        NumberAnimation {
            target: barStrip
            property: "opacity"
            to: 0
            duration: 150
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: barTranslate
            property: "y"
            to: -18
            duration: 150
            easing.type: Easing.OutQuad
        }

        NumberAnimation {
            target: barStrip
            property: "scale"
            to: 0.94
            duration: 150
            easing.type: Easing.OutQuad
        }

    }

    ParallelAnimation {
        id: barEntranceAnim

        NumberAnimation {
            target: barStrip
            property: "opacity"
            from: 0
            to: 1
            duration: 250
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: barTranslate
            property: "y"
            from: -18
            to: 0
            duration: 350
            easing.type: Easing.OutExpo
        }

        NumberAnimation {
            target: barStrip
            property: "scale"
            from: 0.94
            to: 1
            duration: 350
            easing.type: Easing.OutExpo
        }

    }

    SequentialAnimation {
        id: barStyleSwitchAnim

        ParallelAnimation {
            NumberAnimation {
                target: barStrip
                property: "opacity"
                to: 0
                duration: 150
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: barTranslate
                property: "y"
                to: -18
                duration: 150
                easing.type: Easing.OutQuad
            }

            NumberAnimation {
                target: barStrip
                property: "scale"
                to: 0.94
                duration: 150
                easing.type: Easing.OutQuad
            }

        }

        ScriptAction {
            script: {
                root.activeBarStyle = SettingsService.barStyle;
                root.currentBarMarginTop = Qt.binding(() => {
                    return root.barSurface.barMarginTop;
                });
                root.currentBarMarginSide = Qt.binding(() => {
                    return root.barSurface.barMarginSide;
                });
                root.currentBarHeight = Qt.binding(() => {
                    return root.barSurface.barHeight;
                });
                barTranslate.y = -18;
                barStrip.scale = 0.94;
                barStrip.opacity = 0;
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: barStrip
                property: "opacity"
                from: 0
                to: 1
                duration: 250
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: barTranslate
                property: "y"
                from: -18
                to: 0
                duration: 350
                easing.type: Easing.OutExpo
            }

            NumberAnimation {
                target: barStrip
                property: "scale"
                from: 0.94
                to: 1
                duration: 350
                easing.type: Easing.OutExpo
            }

        }

    }

    Connections {
        function onSettingsLoadedChanged() {
            if (SettingsService.settingsLoaded) {
                root.activeBarStyle = SettingsService.barStyle;
                root.currentBarMarginTop = Qt.binding(() => {
                    return root.barSurface.barMarginTop;
                });
                root.currentBarMarginSide = Qt.binding(() => {
                    return root.barSurface.barMarginSide;
                });
                root.currentBarHeight = Qt.binding(() => {
                    return root.barSurface.barHeight;
                });
            }
        }

        function onBarStyleChanged() {
            root.triggerStyleSwitch();
        }

        target: SettingsService
    }

    Item {
        id: unifiedShadowGroup

        anchors.fill: parent
        layer.enabled: HyprlandService.hyprShadow && root.activeBarStyle === "minflair"

        Bar {
            id: barStrip

            activeBarStyle: root.activeBarStyle
            z: root.activeHost === barStrip ? 5 : 1
            notificationService: root.notificationService
            mainPanelWidget: barPopups.dashboardLoader.item
            x: root.isCompact ? ((root.width - barStrip.width) / 2) : root.currentBarMarginSide
            y: root.currentBarMarginTop
            width: root.isCompact ? (barStrip.implicitWidth > 0 ? barStrip.implicitWidth : 180) : (root.width - root.currentBarMarginSide * 2)
            height: ((SettingsService.barIslandMode || SettingsService.barNotchMode) && barStrip.currentHeight > 0) ? barStrip.currentHeight : root.currentBarHeight
            transformOrigin: Item.Top
            Component.onCompleted: {
                root.isShellReady = true;
            }
            transform: [
                Translate {
                    id: barTranslate

                    y: 0
                }
            ]
        }

        BarPopups {
            id: barPopups

            z: (barPopups.notificationOverlay.isOpen || barPopups.isFloatingPopupVisible) ? 25 : 0
            anchors.fill: parent
            notificationService: root.notificationService
            popupStartY: root.barSurface.popupStartY
            activeBarStyle: root.activeBarStyle
            isCompact: root.isCompact
            usesFloatingPopups: root.usesFloatingPopups
            hasExpandableHost: root.hasExpandableHost
            activeHost: root.activeHost
            barStripX: barStrip.x
            barStripCenterX: barStrip.centerX
            barStripCenterWidth: barStrip.centerWidth
        }

        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.alpha(Theme.shadow, 0.85)
            blurMax: HyprlandService.hyprShadowRange * 2
            shadowBlur: 1
            shadowVerticalOffset: 0
            shadowHorizontalOffset: 0
        }

    }

    mask: Region {
        Region {
            x: root.activeBarStyle === "convex" ? barStrip.x : 0
            y: root.activeBarStyle === "convex" ? barStrip.y : 0
            width: root.activeBarStyle === "convex" ? barStrip.width : 0
            height: root.activeBarStyle === "convex" ? 32 : 0
        }

        // Center (Island, Notch, Convex) or Full Width (Minflair, Framed)
        Region {
            x: root.isCompact ? (barStrip.x + barStrip.centerX - 16) : (barStrip.x - 16)
            y: Math.max(0, barStrip.y - 24)
            width: root.isCompact ? (barStrip.centerWidth + 32) : (barStrip.width + 32)
            height: barStrip.height + 40
        }

        // Left Section (Convex)
        Region {
            x: root.activeBarStyle === "convex" ? barStrip.x : 0
            y: root.activeBarStyle === "convex" ? barStrip.y : 0
            width: root.activeBarStyle === "convex" ? barStrip.leftWidth : 0
            height: root.activeBarStyle === "convex" ? barStrip.height + 24 : 0
        }

        // Right Section (Convex)
        Region {
            x: root.activeBarStyle === "convex" ? (barStrip.x + barStrip.width - barStrip.rightWidth) : 0
            y: root.activeBarStyle === "convex" ? barStrip.y : 0
            width: root.activeBarStyle === "convex" ? (barStrip.rightWidth + 16) : 0
            height: root.activeBarStyle === "convex" ? barStrip.height + 24 : 0
        }

        // Floating Popups Overlay
        Region {
            property bool isActive: barPopups.isFloatingPopupVisible

            x: 0
            y: 0
            width: isActive ? root.width : 0
            height: isActive ? root.height : 0
        }

        // Expandable Host Overlay
        Region {
            property bool isActive: root.hasExpandableHost && root.activeHost && root.activeHost.isOverlayActive

            x: isActive ? (root.activeHost.isOpen ? 0 : root.activeHost.blockX) : 0
            y: isActive ? (root.activeHost.isOpen ? 0 : root.activeHost.blockY) : 0
            width: isActive ? (root.activeHost.isOpen ? root.width : root.activeHost.blockWidth) : 0
            height: isActive ? (root.activeHost.isOpen ? root.height : root.activeHost.blockHeight) : 0
        }

        // Notification Overlay
        Region {
            property var notif: barPopups.notificationOverlay

            x: notif.blockX
            y: notif.blockY
            width: notif.blockWidth
            height: notif.blockHeight
        }

    }

}
