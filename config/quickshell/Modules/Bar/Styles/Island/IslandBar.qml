import QtQuick
import Quickshell
import qs.Core
import qs.Core.Services
import qs.Modules.Bar

Item {
    id: islandBar

    required property var notificationService
    property var mainPanelWidget: null
    readonly property string currentPanel: AppState.activeWidget
    readonly property bool isHostPanel: SettingsService.barIslandMode && (currentPanel === "clock" || currentPanel === "dashboard" || currentPanel === "controlCenter" || currentPanel === "notificationsCenter" || currentPanel === "music" || currentPanel === "launcher" || currentPanel === "clipboard" || currentPanel === "wallpaper" || currentPanel === "screenshot" || currentPanel === "powerMenu")
    property string activePanelName: ""
    readonly property string effectivePanel: (AppState.activeWidget !== "" && islandBar.isHostPanel) ? AppState.activeWidget : activePanelName
    property bool isOpen: false
    property bool isRemoving: false
    readonly property bool hasPlayingMedia: MprisService.activePlayer !== null && (((MprisService.activePlayer.trackTitle || "").trim() !== "") || ((MprisService.activePlayer.trackArtist || "").trim() !== ""))
    readonly property bool showMediaOnRight: (SettingsService.islandRightMode === "music") || (SettingsService.islandRightMode === "auto" && hasPlayingMedia)
    property string currentIslandTarget: ""
    readonly property string activeIslandTarget: (isOpen || isRemoving) && currentIslandTarget !== "" ? currentIslandTarget : getTargetPill(effectivePanel)
    readonly property bool isOverlayActive: isOpen || (leftPill.openProgress > 0.001) || (centerPill.openProgress > 0.001) || (rightPill.openProgress > 0.001) || isRemoving
    readonly property bool needsFocus: (effectivePanel === "launcher" || effectivePanel === "clipboard" || effectivePanel === "wallpaper" || effectivePanel === "powerMenu" || effectivePanel === "screenshot")
    readonly property bool hasActiveNotifications: centerPill.hasActiveNotifications
    readonly property real notifProgress: centerPill.notifProgress
    readonly property bool isOccupied: isOverlayActive || hasActiveNotifications
    readonly property var activeItem: {
        if (activeIslandTarget === "left")
            return leftPill.activeItem;

        if (activeIslandTarget === "right")
            return rightPill.activeItem;

        return centerPill.activeItem;
    }
    // Bar Style Interface
    readonly property real leftWidth: 0
    readonly property real rightWidth: 0
    readonly property real centerX: leftPill ? leftPill.x : 0
    readonly property real centerWidth: (leftPill && rightPill) ? Math.max(0, (rightPill.x + rightPill.width) - leftPill.x) : width
    readonly property bool isExpanded: false
    readonly property string activeBarStyle: "island"
    // Geometry exposed for popupSurface mask
    readonly property real blockX: {
        if (activeIslandTarget === "left")
            return islandBar.x + leftPill.x + (leftPill.isTranslated ? -4 : 0);

        if (activeIslandTarget === "right")
            return islandBar.x + rightPill.x + (rightPill.isTranslated ? 4 : 0);

        return islandBar.x + centerPill.x;
    }
    readonly property real blockY: {
        if (activeIslandTarget === "left")
            return leftPill.y + (leftPill.isTranslated ? 4 : 0);

        if (activeIslandTarget === "right")
            return rightPill.y + (rightPill.isTranslated ? 4 : 0);

        return centerPill.y + (centerPill.isTranslated ? 4 : 0);
    }
    readonly property real blockWidth: {
        if (activeIslandTarget === "left")
            return leftPill.width;

        if (activeIslandTarget === "right")
            return rightPill.width;

        return centerPill.width;
    }
    readonly property real blockHeight: {
        if (activeIslandTarget === "left")
            return leftPill.height;

        if (activeIslandTarget === "right")
            return rightPill.height;

        return centerPill.height;
    }
    readonly property real currentHeight: Math.max(leftPill.height + (leftPill.isTranslated ? 4 : 0), Math.max(centerPill.height + (centerPill.isTranslated ? 4 : 0), rightPill.height + (rightPill.isTranslated ? 4 : 0)))
    readonly property real totalIdleWidth: (leftPill && rightPill) ? Math.max(0, (rightPill.x + rightPill.width) - leftPill.x) : 260

    function getTargetPill(panel) {
        if (panel === "dashboard")
            return "left";

        if (islandBar.showMediaOnRight) {
            if (panel === "music")
                return "right";

            if (panel === "controlCenter")
                return "center";

        } else {
            if (panel === "controlCenter")
                return "right";

            if (panel === "music")
                return "center";

        }
        if (panel === "clock" || panel === "launcher" || panel === "clipboard" || panel === "wallpaper" || panel === "notificationsCenter" || panel === "screenshot" || panel === "powerMenu")
            return "center";

        return "";
    }

    function syncDimensions() {
        if (!isOccupied && totalIdleWidth > 0) {
            AppState.barIslandWidth = totalIdleWidth;
            AppState.islandWidth = totalIdleWidth;
            AppState.barIslandHeight = 32;
            AppState.islandHeight = 32;
        }
    }

    function requestFocus() {
        if (!needsFocus)
            return ;

        let it = activeItem;
        if (it) {
            if (it.resetLauncher)
                it.resetLauncher();
            else if (it.resetClipboard)
                it.resetClipboard();
            else if (it.resetWallpaperSelector)
                it.resetWallpaperSelector();
            else if (it.resetPowerMenu)
                it.resetPowerMenu();
            else if (it.resetScreenCapture)
                it.resetScreenCapture();
            if (it.initialFocusItem) {
                if (it.initialFocusItem.textField)
                    it.initialFocusItem.textField.forceActiveFocus();
                else
                    it.initialFocusItem.forceActiveFocus();
            } else {
                it.forceActiveFocus();
            }
        }
    }

    function triggerFocus() {
        focusTimer.restart();
    }

    function updateContent(newPanel) {
        if (!SettingsService.barIslandMode) {
            closeImmediately();
            return ;
        }
        let target = getTargetPill(newPanel);
        if (target === "") {
            if (isOpen || isRemoving)
                close();

            return ;
        }
        let comp = islandComponents.getComponent(newPanel);
        if (!comp)
            return ;

        currentIslandTarget = target;
        activePanelName = newPanel;
        isRemoving = false;
        isOpen = true;
        AppState.isIslandOpen = true;
        leftPill.openProgress = (target === "left") ? 1 : 0;
        centerPill.openProgress = (target === "center") ? 1 : 0;
        rightPill.openProgress = (target === "right") ? 1 : 0;
    }

    function close() {
        if (!isOpen && !isRemoving)
            return ;

        isRemoving = true;
        isOpen = false;
        leftPill.openProgress = 0;
        centerPill.openProgress = 0;
        rightPill.openProgress = 0;
        if (!HyprlandService.enableAnimations)
            finishClosing();

    }

    function checkFinishClosing() {
        if (isRemoving && leftPill.openProgress === 0 && centerPill.openProgress === 0 && rightPill.openProgress === 0)
            finishClosing();

    }

    function finishClosing() {
        if (isRemoving) {
            isRemoving = false;
            currentIslandTarget = "";
            activePanelName = "";
            AppState.isIslandOpen = false;
            if (AppState.activeWidget === effectivePanel || isHostPanel)
                AppState.activeWidget = "";

            if (hasActiveNotifications && !centerPill.isRemovingNotif)
                centerPill.restartDisplayTimer();

        }
    }

    function closeImmediately() {
        isRemoving = false;
        isOpen = false;
        currentIslandTarget = "";
        leftPill.openProgress = 0;
        centerPill.openProgress = 0;
        rightPill.openProgress = 0;
        activePanelName = "";
        AppState.isIslandOpen = false;
        if (SettingsService.barIslandMode && isHostPanel)
            AppState.activeWidget = "";

    }

    Keys.forwardTo: {
        if (!needsFocus || !activeItem || !activeItem.initialFocusItem)
            return [];

        let it = activeItem.initialFocusItem;
        return it.textField ? [it.textField, it] : [it];
    }
    Keys.enabled: isOpen && needsFocus
    Keys.onEscapePressed: close()
    anchors.left: parent ? parent.left : undefined
    anchors.right: parent ? parent.right : undefined
    anchors.top: parent ? parent.top : undefined
    implicitHeight: currentHeight
    height: currentHeight
    onTotalIdleWidthChanged: syncDimensions()
    onCurrentHeightChanged: syncDimensions()
    Component.onCompleted: syncDimensions()
    onHasActiveNotificationsChanged: {
        if (SettingsService.barIslandMode) {
            let active = hasActiveNotifications && !centerPill.isRemovingNotif;
            AppState.hasActiveNotification = active;
            AppState.activeNotificationWidth = active ? centerPill.notifW : 0;
            AppState.activeNotificationHeight = active ? centerPill.notifH : 0;
        }
    }

    Timer {
        id: focusTimer

        interval: 30
        repeat: false
        onTriggered: {
            islandBar.requestFocus();
            focusRetryTimer.restart();
        }
    }

    Timer {
        id: focusRetryTimer

        interval: 90
        repeat: false
        onTriggered: islandBar.requestFocus()
    }

    IslandComponents {
        id: islandComponents

        islandBar: islandBar
        notificationService: islandBar.notificationService
    }

    Connections {
        function onActiveWidgetChanged() {
            if (SettingsService.barIslandMode)
                updateContent(AppState.activeWidget);

        }

        target: AppState
    }

    Connections {
        function onBarIslandModeChanged() {
            if (!SettingsService.barIslandMode)
                closeImmediately();
            else
                updateContent(AppState.activeWidget);
        }

        target: SettingsService
    }

    // MAIN THREE-ISLAND CONTAINER
    Item {
        id: islandContainer

        anchors.left: parent ? parent.left : undefined
        anchors.right: parent ? parent.right : undefined
        anchors.top: parent ? parent.top : undefined
        height: islandBar.currentHeight

        IslandLeftPill {
            id: leftPill

            islandBar: islandBar
            islandComponents: islandComponents
            centerPill: centerPill
        }

        IslandCenterPill {
            id: centerPill

            islandBar: islandBar
            islandComponents: islandComponents
            islandContainer: islandContainer
            notificationService: islandBar.notificationService
        }

        IslandRightPill {
            id: rightPill

            islandBar: islandBar
            islandComponents: islandComponents
            islandContainer: islandContainer
            centerPill: centerPill
        }

    }

}
