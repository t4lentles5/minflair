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
    property bool isShellReady: false
    property string activeBarStyle: ""
    property string _currentStyle: activeBarStyle
    readonly property bool isConvexMode: SettingsService.barConvexMode
    readonly property bool isExiting: !isConvexMode
    property int barHeight: BarStyleConfig.barHeight("convex")
    property real animatedBarHeight: barHeight
    property int bezelSize: 8
    property bool hasFullscreen: (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.hasFullscreen) ? HyprlandService.isTrueFullscreen : false
    property real fsTransitionProg: hasFullscreen ? 0 : 1
    readonly property var styleData: BarStyleConfig.styleOf("convex")
    readonly property bool hasExpandableHost: styleData.hasExpandableHost
    readonly property bool usesFloatingPopups: styleData.usesFloatingPopups
    readonly property bool isPill: styleData.isPill
    readonly property bool needsFocus: AppState.isFocusPopupOpen && convexPanels.hasAnyDrawerOpen
    property bool loadConvexBar: true

    function triggerStyleSwitch() {
        root.activeBarStyle = SettingsService.barStyle;
        root._currentStyle = SettingsService.barStyle;
    }

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: needsFocus ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    focusable: needsFocus
    color: "transparent"
    Component.onCompleted: {
        activeBarStyle = SettingsService.barStyle;
        _currentStyle = SettingsService.barStyle;
        Qt.callLater(() => {
            isShellReady = true;
        });
    }
    onVisibleChanged: {
        if (visible && SettingsService.barStyle === "convex") {
            shellFrameContainer.enableTransitionAnim = false;
            root.activeBarStyle = "convex";
            root._currentStyle = "convex";
            barContainer.switchOpacity = 1;
            barContainer.scale = 1;
            convexBarTranslate.y = 0;
        }
    }

    Connections {
        function onSettingsLoadedChanged() {
            if (SettingsService.settingsLoaded) {
                root.activeBarStyle = SettingsService.barStyle;
                root._currentStyle = SettingsService.barStyle;
            }
        }

        function onBarStyleChanged() {
            root.triggerStyleSwitch();
        }

        target: SettingsService
    }

    Process {
        id: slurpCheckProcess

        command: ["sh", "-c", "pidof slurp"]
        onExited: {
            if (exitCode !== 0) {
                if (AppState.activePopup !== "")
                    AppState.activePopup = "";

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

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    ConvexExclusions {
        hasFullscreen: root.hasFullscreen
        barHeight: root.barHeight
        bezelSize: root.bezelSize
        isExiting: root.isExiting
    }

    Item {
        id: unifiedShadowGroup

        anchors.fill: parent
        opacity: root.isConvexMode ? 1 : 0
        layer.enabled: HyprlandService.hyprShadow

        ConvexPanels {
            id: convexPanels

            z: 1
            anchors.fill: parent
            barHeight: root.barHeight
            bezelSize: root.bezelSize
            notificationService: root.notificationService
        }

        BarPopups {
            id: barPopups

            z: (barPopups.notificationOverlay.isOpen || barPopups.isFloatingPopupVisible) ? 25 : 0
            anchors.fill: parent
            notificationService: root.notificationService
            popupStartY: root.barHeight
            activeBarStyle: root.activeBarStyle
            isPill: false
            usesFloatingPopups: true
            hasExpandableHost: true
            activeHost: null
            barStripX: barContainer.activeItem ? (barContainer.activeItem.x || 0) : 0
            barStripCenterX: barContainer.activeItem ? (barContainer.activeItem.centerX || 0) : 0
            barStripCenterWidth: barContainer.activeItem ? (barContainer.activeItem.centerWidth || 0) : 0
        }

        ConvexFrameBezel {
            id: shellFrameContainer

            z: 10
            hasFrame: true
            isShellReady: root.isShellReady
            barHeight: Math.round(root.animatedBarHeight)
            activeBarStyle: root.activeBarStyle
            bezelSize: root.bezelSize
            fsTransitionProg: root.fsTransitionProg
        }

        Item {
            id: barContainer

            property QtObject activeItem: convexLoader.item
            property real switchOpacity: 1

            z: 20
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: (activeItem && (activeItem.centerHeight || 0) > root.barHeight) ? activeItem.centerHeight : root.barHeight
            transformOrigin: Item.Top
            opacity: root.fsTransitionProg * switchOpacity
            visible: opacity > 0.01
            transform: [
                Translate {
                    id: convexBarTranslate

                    y: 0
                }
            ]

            Loader {
                id: convexLoader

                anchors.fill: parent
                active: root.loadConvexBar
                visible: true
                source: "ConvexBar.qml"
                onLoaded: {
                    if (item) {
                        item.notificationService = root.notificationService;
                        item.mainPanelWidget = Qt.binding(() => {
                            return barPopups.dashboardLoader.item;
                        });
                    }
                }
            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: Constants.animFast
                easing.type: Easing.OutCubic
            }

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

    Behavior on fsTransitionProg {
        NumberAnimation {
            duration: Constants.animNormal
            easing.type: Easing.InOutCubic
        }

    }

    mask: Region {
        // Top border + Bar
        Region {
            x: 0
            y: 0
            width: root.width
            height: root.barHeight * root.fsTransitionProg
        }

        // Left border
        Region {
            x: 0
            y: root.barHeight * root.fsTransitionProg
            width: root.bezelSize * root.fsTransitionProg
            height: root.height
        }

        // Right border
        Region {
            x: root.width - (root.bezelSize * root.fsTransitionProg)
            y: root.barHeight * root.fsTransitionProg
            width: root.bezelSize * root.fsTransitionProg
            height: root.height
        }

        // Bottom border
        Region {
            x: root.bezelSize * root.fsTransitionProg
            y: root.height - (root.bezelSize * root.fsTransitionProg)
            width: root.width - (2 * root.bezelSize * root.fsTransitionProg)
            height: root.bezelSize * root.fsTransitionProg
        }

        // Active Popups Overlay (Full Screen for Clicks/Focus)
        Region {
            property bool isActive: barPopups.isFloatingPopupVisible || convexPanels.hasAnyDrawerOpen || convexPanels.isConvexPopupOpen

            x: 0
            y: 0
            width: isActive ? root.width : 0
            height: isActive ? root.height : 0
        }

        // Notification Overlay
        Region {
            readonly property bool isNotifOpen: barPopups.notificationOverlay.isOpen
            readonly property real notifX: barPopups.notificationOverlay.blockX
            readonly property real notifY: barPopups.notificationOverlay.blockY
            readonly property real notifW: barPopups.notificationOverlay.blockWidth
            readonly property real notifH: barPopups.notificationOverlay.blockHeight

            x: isNotifOpen ? (notifX - 24) : 0
            y: isNotifOpen ? notifY : 0
            width: isNotifOpen ? (notifW + 24) : 0
            height: isNotifOpen ? (notifH + 24) : 0
        }

        // Convex Center Notch Expanded Region
        Region {
            readonly property bool isConvexExpanded: root.activeBarStyle === "convex" && barContainer.activeItem && (barContainer.activeItem.centerHeight > root.barHeight)
            readonly property real cX: (root.activeBarStyle === "convex" && barContainer.activeItem) ? (barContainer.activeItem.centerX || 0) : 0
            readonly property real cW: (root.activeBarStyle === "convex" && barContainer.activeItem) ? (barContainer.activeItem.centerWidth || 0) : 0
            readonly property real cH: (root.activeBarStyle === "convex" && barContainer.activeItem) ? (barContainer.activeItem.centerHeight || 0) : 0

            x: isConvexExpanded ? (cX - 8) : 0
            y: 0
            width: isConvexExpanded ? (cW + 16) : 0
            height: isConvexExpanded ? (cH + 16) : 0
        }

    }

}
