import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Bar.Styles.Convex
import qs.Modules.Clipboard
import qs.Modules.Launcher
import qs.Modules.PowerMenu
import qs.Modules.ScreenCapture
import qs.Modules.WallpaperSelector

Item {
    id: root

    property int edge: Qt.BottomEdge
    readonly property bool isBottom: true
    readonly property string activeWidgetId: {
        if (AppState.isWidgetOpen("launcher"))
            return "launcher";

        if (AppState.isWidgetOpen("clipboard"))
            return "clipboard";

        if (AppState.isWidgetOpen("wallpaper"))
            return "wallpaper";

        if (AppState.isWidgetOpen("powerMenu"))
            return "powerMenu";

        if (AppState.isWidgetOpen("screenshot"))
            return "screenshot";

        return "";
    }
    property string displayedWidgetId: ""
    readonly property bool isOpen: activeWidgetId !== ""
    property bool isClosing: false
    property bool _visible: false
    readonly property bool isCompactWidget: displayedWidgetId === "powerMenu" || displayedWidgetId === "screenshot"
    property int cornerRadius: isCompactWidget ? Constants.sizeMd : Constants.sizeLg * 2
    property int contentPadding: isCompactWidget ? 0 : Constants.sizeLg
    property color backgroundColor: Theme.bg
    property real contentWidth: loader.item ? (loader.item.implicitWidth > 0 ? loader.item.implicitWidth : loader.item.width) : 0
    property real contentHeight: loader.item ? (loader.item.implicitHeight > 0 ? loader.item.implicitHeight : loader.item.height) : 0
    property real safeMarginX: cornerRadius * 2 + (contentPadding * 2)
    property real safeMarginY: isCompactWidget ? 0 : (contentPadding * 2)
    property real openProgress: 0
    property real contentCrossFade: 1
    property real targetWidth: contentWidth > 0 ? contentWidth + safeMarginX : 0
    property real targetHeight: contentHeight > 0 ? contentHeight + safeMarginY : 0
    property real smoothWidth: targetWidth
    property real smoothHeight: targetHeight
    readonly property Component activeSourceComponent: {
        switch (displayedWidgetId) {
        case "launcher":
            return launcherComp;
        case "clipboard":
            return clipboardComp;
        case "wallpaper":
            return wallpaperComp;
        case "powerMenu":
            return powerMenuComp;
        case "screenshot":
            return screenshotComp;
        default:
            return null;
        }
    }

    signal fullyClosed()

    function close() {
        if (root.activeWidgetId !== "")
            AppState.closeWidget(root.activeWidgetId);
        else
            AppState.closeAllWidgets();
    }

    function activateCurrentItem() {
        if (!loader.item)
            return ;

        if ("widget" in loader.item || loader.item.hasOwnProperty("widget"))
            loader.item.widget = widgetProxy;

        if (typeof loader.item.resetLauncher === "function")
            loader.item.resetLauncher();

        if (typeof loader.item.resetClipboard === "function")
            loader.item.resetClipboard();

        if (typeof loader.item.resetWallpaperSelector === "function")
            loader.item.resetWallpaperSelector();

        if (typeof loader.item.resetPowerMenu === "function")
            loader.item.resetPowerMenu();

        if (typeof loader.item.resetScreenCapture === "function")
            loader.item.resetScreenCapture();

        Qt.callLater(() => {
            if (loader.item) {
                if (loader.item.initialFocusItem)
                    loader.item.initialFocusItem.forceActiveFocus();
                else if (typeof loader.item.forceActiveFocus === "function")
                    loader.item.forceActiveFocus();
            }
        });
    }

    width: Math.round(smoothWidth)
    height: Math.round(smoothHeight)
    implicitWidth: Math.round(smoothWidth)
    implicitHeight: Math.round(smoothHeight)
    visible: _visible
    onActiveWidgetIdChanged: {
        if (activeWidgetId !== "") {
            if (isOpen && displayedWidgetId !== "" && displayedWidgetId !== activeWidgetId) {
                // Switching widgets while drawer is already open: morph container and fade content
                contentCrossFade = 0;
                displayedWidgetId = activeWidgetId;
                contentFadeTimer.restart();
            } else {
                displayedWidgetId = activeWidgetId;
                contentCrossFade = 1;
            }
        }
    }
    onIsOpenChanged: {
        if (isOpen) {
            isClosing = false;
            closeDelayTimer.stop();
            _visible = true;
            if (activeWidgetId !== "")
                displayedWidgetId = activeWidgetId;

            activateCurrentItem();
            openProgress = 1;
        } else {
            isClosing = true;
            openProgress = 0;
            if (!HyprlandService.enableAnimations) {
                _visible = false;
                displayedWidgetId = "";
                isClosing = false;
                root.fullyClosed();
            } else {
                closeDelayTimer.start();
            }
        }
    }

    Timer {
        id: contentFadeTimer

        interval: 35
        repeat: false
        onTriggered: {
            contentCrossFade = 1;
            root.activateCurrentItem();
        }
    }

    Timer {
        id: closeDelayTimer

        interval: Constants.animNormal + 50
        repeat: false
        onTriggered: {
            if (!root.isOpen) {
                root._visible = false;
                root.displayedWidgetId = "";
                root.isClosing = false;
                root.fullyClosed();
            }
        }
    }

    Item {
        id: contentContainer

        readonly property real currentWidth: smoothWidth
        readonly property real currentHeight: Math.max(smoothHeight * openProgress, 0.01)

        clip: true
        width: Math.round(currentWidth)
        height: Math.round(currentHeight)
        Keys.forwardTo: (loader.item && loader.item.initialFocusItem) ? [loader.item.initialFocusItem] : []
        Keys.enabled: root.isOpen
        Keys.onEscapePressed: {
            root.close();
        }
        x: Math.round((root.width - currentWidth) / 2)
        y: Math.round(smoothHeight - currentHeight)

        ConvexDrawerShape {
            id: bg

            anchors.fill: parent
            color: root.backgroundColor
            cornerRadius: root.cornerRadius
            edge: root.edge
            enableShadow: false
        }

        Loader {
            id: loader

            sourceComponent: root.activeSourceComponent
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Math.round(root.safeMarginY / 2)
            width: root.contentWidth
            height: root.contentHeight
            opacity: (root.isClosing ? Math.min(1, Math.max(0, (root.openProgress - 0.4) / 0.6)) : Math.min(1, Math.max(0, (root.openProgress - 0.2) / 0.8))) * root.contentCrossFade
            scale: root.isClosing ? (0.94 + 0.06 * Math.min(1, Math.max(0, (root.openProgress - 0.3) / 0.7))) : (0.94 + 0.06 * Math.min(1, Math.max(0, (root.openProgress - 0.15) / 0.85)))
            onLoaded: {
                root.activateCurrentItem();
            }
        }

    }

    QtObject {
        id: widgetProxy

        property bool isOpen: root.isOpen
        property int cornerRadius: root.cornerRadius
        property real openProgress: root.openProgress
        property real bounceProgress: root.openProgress
        property int preferredWidth: root.contentWidth
        property int preferredHeight: root.contentHeight

        function close() {
            root.close();
        }

        onIsOpenChanged: {
            if (!isOpen && root.isOpen)
                root.close();

        }
    }

    Binding {
        target: widgetProxy
        property: "isOpen"
        value: root.isOpen
    }

    Component {
        id: launcherComp

        LauncherContent {
            widget: widgetProxy
        }

    }

    Component {
        id: clipboardComp

        ClipboardContent {
            widget: widgetProxy
        }

    }

    Component {
        id: wallpaperComp

        WallpaperSelectorContent {
            widget: widgetProxy
        }

    }

    Component {
        id: powerMenuComp

        PowerMenuContent {
            widget: widgetProxy
        }

    }

    Component {
        id: screenshotComp

        ScreenCaptureContent {
            widget: widgetProxy
        }

    }

    // Island-matched opening/closing physics
    Behavior on openProgress {
        enabled: HyprlandService.enableAnimations

        NumberAnimation {
            duration: root.isClosing ? Constants.animNormal : Constants.animExpressive
            easing.type: root.isClosing ? Easing.OutCubic : Easing.OutQuint
            onRunningChanged: {
                if (!running && root.isClosing) {
                    root._visible = false;
                    root.displayedWidgetId = "";
                    root.isClosing = false;
                    root.fullyClosed();
                }
            }
        }

    }

    // Island-matched morphing durations
    Behavior on smoothHeight {
        enabled: HyprlandService.enableAnimations && root.isOpen

        NumberAnimation {
            duration: Constants.animSlow
            easing.type: Easing.OutQuint
        }

    }

    Behavior on smoothWidth {
        enabled: HyprlandService.enableAnimations && root.isOpen

        NumberAnimation {
            duration: Constants.animSlow
            easing.type: Easing.OutQuint
        }

    }

    Behavior on cornerRadius {
        enabled: HyprlandService.enableAnimations && root.isOpen

        NumberAnimation {
            duration: Constants.animSlow
            easing.type: Easing.OutQuint
        }

    }

    Behavior on contentCrossFade {
        enabled: HyprlandService.enableAnimations

        NumberAnimation {
            duration: Constants.animFast
            easing.type: Easing.OutCubic
        }

    }

}
