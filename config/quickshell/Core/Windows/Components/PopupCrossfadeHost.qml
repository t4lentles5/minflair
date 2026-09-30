import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Bar.Widgets.Dashboard as DashboardModule
import qs.Modules.Clipboard as ClipboardModule
import qs.Modules.ControlCenter as ControlCenterModule
import qs.Modules.Launcher as LauncherModule
import qs.Modules.MusicPopup as MusicModule
import qs.Modules.NotificationCenter as NotificationCenterModule
import qs.Modules.WallpaperSelector as WallpaperModule

Item {
    id: root

    property var notificationService: null
    property string barMode: "island" // "island" or "notch"
    property Item visualContainer: null // The shape item that we animate
    property real contentHorizontalPadding: 0
    property real contentVerticalPadding: 0
    property real defaultWidth: 0
    property real defaultHeight: 0
    readonly property string currentPopup: AppState.activePopup
    readonly property bool isHostPopup: (barMode === "island" && SettingsService.barIslandMode || barMode === "notch" && SettingsService.barNotchMode) && (currentPopup === "dashboard" || currentPopup === "controlCenter" || currentPopup === "notificationsCenter" || currentPopup === "music" || currentPopup === "launcher" || currentPopup === "clipboard" || currentPopup === "wallpaper")
    property string activePopupName: ""
    readonly property string effectivePopup: (AppState.activePopup !== "" && root.isHostPopup) ? AppState.activePopup : activePopupName
    readonly property var activeItem: loaderA ? loaderA.item : null
    property bool isOpen: false
    property bool isRemoving: false
    property bool isHandover: false
    readonly property bool isOverlayActive: (isOpen || (visualContainer && visualContainer.openProgress > 0.001) || isRemoving || isHandover)
    readonly property bool needsFocus: (effectivePopup === "launcher" || effectivePopup === "clipboard" || effectivePopup === "wallpaper")
    property alias contentLoader: loaderA

    function getComponent(popup) {
        switch (popup) {
        case "dashboard":
            return dashboardComp;
        case "controlCenter":
            return controlCenterComp;
        case "notificationsCenter":
            return notificationsCenterComp;
        case "music":
            return musicComp;
        case "launcher":
            return launcherComp;
        case "clipboard":
            return clipboardComp;
        case "wallpaper":
            return wallpaperComp;
        default:
            return null;
        }
    }

    function getTargetWidth(popup, item) {
        if (item && item.implicitWidth > 0)
            return item.implicitWidth + contentHorizontalPadding;

        switch (popup) {
        case "wallpaper":
            return 1008 + contentHorizontalPadding;
        case "launcher":
            return 640 + contentHorizontalPadding;
        case "clipboard":
            return 520 + contentHorizontalPadding;
        case "dashboard":
            return 720 + contentHorizontalPadding;
        case "controlCenter":
            return 400 + contentHorizontalPadding;
        case "notificationsCenter":
            return 400 + contentHorizontalPadding;
        case "music":
            return 320 + contentHorizontalPadding;
        }
        return defaultWidth;
    }

    function getTargetHeight(popup, item) {
        if (item && item.implicitHeight > 0)
            return item.implicitHeight + contentVerticalPadding;

        switch (popup) {
        case "wallpaper":
            return 216 + contentVerticalPadding;
        case "launcher":
            return 400 + contentVerticalPadding;
        case "clipboard":
            return 360 + contentVerticalPadding;
        case "dashboard":
            return 500 + contentVerticalPadding;
        case "controlCenter":
            return 440 + contentVerticalPadding;
        case "notificationsCenter":
            return 440 + contentVerticalPadding;
        case "music":
            return 180 + contentVerticalPadding;
        }
        return defaultHeight;
    }

    function getContentWidth(popup, item) {
        return Math.max(0, getTargetWidth(popup, item) - contentHorizontalPadding);
    }

    function getContentHeight(popup, item) {
        return Math.max(0, getTargetHeight(popup, item) - contentVerticalPadding);
    }

    function close() {
        if (isRemoving)
            return ;

        isRemoving = true;
        isOpen = false;
        if (visualContainer) {
            visualContainer.fromWidth = root.defaultWidth;
            visualContainer.fromHeight = root.defaultHeight;
            if (visualContainer.fromRadius !== undefined && barMode === "island") {
                let nh = (AppState.hasActiveNotification && AppState.activeNotificationHeight > 0) ? AppState.activeNotificationHeight : 0;
                visualContainer.fromRadius = nh > 0 ? Constants.sizeSm : root.defaultHeight / 2;
            }
            visualContainer.openProgress = 0;
        }
        if (!HyprlandService.enableAnimations)
            finishClosing();

    }

    function finishClosing() {
        if (isRemoving) {
            isRemoving = false;
            isHandover = true;
            if (barMode === "island")
                AppState.isIslandOpen = false;

            if (barMode === "notch")
                AppState.isNotchOpen = false;

            if (AppState.activePopup === activePopupName || root.isHostPopup)
                AppState.activePopup = "";

            handoverTimer.restart();
        }
    }

    function closeImmediately() {
        handoverTimer.stop();
        isHandover = false;
        isRemoving = false;
        isOpen = false;
        if (visualContainer)
            visualContainer.openProgress = 0;

        loaderA.sourceComponent = null;
        activePopupName = "";
        if (barMode === "island")
            AppState.isIslandOpen = false;

        if (barMode === "notch")
            AppState.isNotchOpen = false;

        if ((barMode === "island" && SettingsService.barIslandMode || barMode === "notch" && SettingsService.barNotchMode) && root.isHostPopup)
            AppState.activePopup = "";

    }

    function updateContent(newPopup) {
        if ((barMode === "island" && !SettingsService.barIslandMode) || (barMode === "notch" && !SettingsService.barNotchMode)) {
            root.closeImmediately();
            return ;
        }
        let isHost = (newPopup === "dashboard" || newPopup === "controlCenter" || newPopup === "notificationsCenter" || newPopup === "music" || newPopup === "launcher" || newPopup === "clipboard" || newPopup === "wallpaper");
        if (!isHost) {
            if (root.isOpen)
                root.close();

            return ;
        }
        let comp = getComponent(newPopup);
        if (!comp)
            return ;

        if (activePopupName !== newPopup) {
            loaderA.sourceComponent = comp;
            activePopupName = newPopup;
        }
        if (!root.isOpen) {
            root.isOpen = true;
            focusTimer.restart();
        }
    }

    function requestFocus() {
        if (!root.needsFocus)
            return ;

        let it = root.activeItem;
        if (it) {
            if (it.resetLauncher)
                it.resetLauncher();
            else if (it.resetClipboard)
                it.resetClipboard();
            else if (it.resetWallpaperSelector)
                it.resetWallpaperSelector();
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

    onIsOpenChanged: {
        if (isOpen) {
            if (barMode === "island")
                AppState.isIslandOpen = true;

            if (barMode === "notch")
                AppState.isNotchOpen = true;

            isRemoving = false;
            isHandover = false;
            handoverTimer.stop();
            if (visualContainer) {
                visualContainer.fromWidth = root.defaultWidth;
                visualContainer.fromHeight = root.defaultHeight;
                if (visualContainer.fromRadius !== undefined && barMode === "island") {
                    let nh = (AppState.hasActiveNotification && AppState.activeNotificationHeight > 0) ? AppState.activeNotificationHeight : 0;
                    visualContainer.fromRadius = nh > 0 ? Constants.sizeSm : root.defaultHeight / 2;
                }
                visualContainer.openProgress = 1;
            }
            focusTimer.restart();
            Qt.callLater(root.requestFocus);
        } else {
            root.close();
        }
    }

    Connections {
        function onActivePopupChanged() {
            if ((barMode === "island" && SettingsService.barIslandMode) || (barMode === "notch" && SettingsService.barNotchMode))
                root.updateContent(AppState.activePopup);

        }

        target: AppState
    }

    Connections {
        function onBarIslandModeChanged() {
            if (barMode !== "island")
                return ;

            if (!SettingsService.barIslandMode)
                root.closeImmediately();
            else
                root.updateContent(AppState.activePopup);
        }

        function onBarNotchModeChanged() {
            if (barMode !== "notch")
                return ;

            if (!SettingsService.barNotchMode)
                root.closeImmediately();
            else
                root.updateContent(AppState.activePopup);
        }

        target: SettingsService
    }

    Timer {
        id: focusTimer

        interval: 40
        repeat: false
        onTriggered: {
            root.requestFocus();
            focusRetryTimer.restart();
        }
    }

    Timer {
        id: focusRetryTimer

        interval: 100
        repeat: false
        onTriggered: root.requestFocus()
    }

    Timer {
        id: handoverTimer

        interval: 60
        repeat: false
        onTriggered: {
            root.isHandover = false;
            root.isRemoving = false;
            loaderA.sourceComponent = null;
            activePopupName = "";
            if ((barMode === "island" && SettingsService.barIslandMode || barMode === "notch" && SettingsService.barNotchMode) && root.isHostPopup)
                AppState.activePopup = "";

        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.isOpen
        onClicked: root.close()
    }

    Loader {
        id: loaderA

        visible: false // Only used for instantiation, rendering happens in parent
    }

    Component {
        id: dashboardComp

        DashboardModule.DashboardContent {
            widget: root.parent
        }

    }

    Component {
        id: controlCenterComp

        ControlCenterModule.ControlCenterContent {
            widget: root.parent
            notificationService: root.notificationService
        }

    }

    Component {
        id: notificationsCenterComp

        NotificationCenterModule.NotificationCenter {
            notificationService: root.notificationService
            controlCenterOpen: true
        }

    }

    Component {
        id: musicComp

        MusicModule.MiniMusicWidget {
            widget: root.parent
        }

    }

    Component {
        id: launcherComp

        LauncherModule.LauncherContent {
            widget: root.parent
        }

    }

    Component {
        id: clipboardComp

        ClipboardModule.ClipboardContent {
            widget: root.parent
        }

    }

    Component {
        id: wallpaperComp

        WallpaperModule.WallpaperSelectorContent {
            widget: root.parent
        }

    }

}
