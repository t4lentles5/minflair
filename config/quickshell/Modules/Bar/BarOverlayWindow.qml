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
    readonly property bool isPill: styleData.isPill
    readonly property QtObject activeHost: SettingsService.barIslandMode ? barStrip : null
    readonly property bool needsFocus: (activeHost && activeHost.isOpen && activeHost.needsFocus)

    function triggerStyleSwitch() {
        if (!root.isShellReady || !SettingsService.settingsLoaded) {
            root.activeBarStyle = SettingsService.barStyle;
            return ;
        }
        let newStyle = SettingsService.barStyle;
        let oldStyle = root.activeBarStyle;
        if (oldStyle === newStyle) {
            let isConvexMode = newStyle === "convex";
            if (!isConvexMode && barStrip.opacity < 0.05) {
                barExitOnlyAnim.stop();
                barStyleSwitchAnim.stop();
                barEntranceAnim.stop();
                barStrip.opacity = 1;
                barTranslate.y = 0;
                barStrip.scale = 1;
            }
            return ;
        }
        let wasConvex = oldStyle === "convex";
        let isConvex = newStyle === "convex";
        if (isConvex) {
            barStyleSwitchAnim.stop();
            barEntranceAnim.stop();
            barExitOnlyAnim.stop();
            barStrip.opacity = 1;
            barTranslate.y = 0;
            barStrip.scale = 1;
            root.activeBarStyle = newStyle;
        } else if (wasConvex) {
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
            let isConvexMode = SettingsService.barStyle === "convex";
            if (!isConvexMode) {
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
            duration: Constants.animFast
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: barTranslate
            property: "y"
            to: -18
            duration: Constants.animFast
            easing.type: Easing.OutQuad
        }

        NumberAnimation {
            target: barStrip
            property: "scale"
            to: 0.94
            duration: Constants.animFast
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
            duration: Constants.animNormal
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: barTranslate
            property: "y"
            from: -18
            to: 0
            duration: Constants.animSlow
            easing.type: Easing.OutExpo
        }

        NumberAnimation {
            target: barStrip
            property: "scale"
            from: 0.94
            to: 1
            duration: Constants.animSlow
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
                duration: Constants.animFast
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: barTranslate
                property: "y"
                to: -18
                duration: Constants.animFast
                easing.type: Easing.OutQuad
            }

            NumberAnimation {
                target: barStrip
                property: "scale"
                to: 0.94
                duration: Constants.animFast
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
                duration: Constants.animNormal
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: barTranslate
                property: "y"
                from: -18
                to: 0
                duration: Constants.animSlow
                easing.type: Easing.OutExpo
            }

            NumberAnimation {
                target: barStrip
                property: "scale"
                from: 0.94
                to: 1
                duration: Constants.animSlow
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
        layer.enabled: false

        MouseArea {
            id: dismissArea

            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            enabled: root.hasExpandableHost && root.activeHost && root.activeHost.isOpen
            onClicked: {
                if (root.activeHost && typeof root.activeHost.close === "function")
                    root.activeHost.close();

                AppState.closeAllWidgets();
            }
        }

        Bar {
            id: barStrip

            activeBarStyle: root.activeBarStyle
            z: (root.activeHost === barStrip && root.activeHost.isOpen) ? 30 : (root.activeHost === barStrip ? 5 : 1)
            notificationService: root.notificationService
            mainPanelWidget: null
            x: root.isPill ? 0 : root.currentBarMarginSide
            y: root.currentBarMarginTop
            width: root.isPill ? root.width : (root.width - root.currentBarMarginSide * 2)
            height: (SettingsService.barIslandMode && barStrip.currentHeight > 0) ? barStrip.currentHeight : root.currentBarHeight
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

        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Theme.shadow
            blurMax: HyprlandService.hyprShadowRange * 2
            shadowBlur: 1
            shadowVerticalOffset: 0
            shadowHorizontalOffset: 0
        }

    }

    mask: Region {
        // Center (Island)
        Region {
            x: root.isPill ? (barStrip.x + barStrip.centerX - 16) : (barStrip.x - 16)
            y: Math.max(0, barStrip.y - 24)
            width: root.isPill ? (barStrip.centerWidth + 32) : (barStrip.width + 32)
            height: barStrip.height + 40
        }

        // Expandable Host Overlay
        Region {
            property bool isActive: root.hasExpandableHost && root.activeHost && root.activeHost.isOverlayActive

            x: isActive ? (root.activeHost.isOpen ? 0 : root.activeHost.blockX) : 0
            y: isActive ? (root.activeHost.isOpen ? 0 : root.activeHost.blockY) : 0
            width: isActive ? (root.activeHost.isOpen ? root.width : root.activeHost.blockWidth) : 0
            height: isActive ? (root.activeHost.isOpen ? root.height : root.activeHost.blockHeight) : 0
        }

    }

}
