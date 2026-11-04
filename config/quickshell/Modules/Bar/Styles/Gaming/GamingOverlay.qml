import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray as QSSysTray
import Quickshell.Wayland
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Bar.Widgets.SystemTray
import qs.Modules.Calendar
import qs.Modules.Clipboard
import qs.Modules.ControlCenter
import qs.Modules.Dashboard
import qs.Modules.Launcher
import qs.Modules.Music
import qs.Modules.NotificationCenter
import qs.Modules.PowerMenu
import qs.Modules.ScreenCapture
import qs.Modules.SystemUsage as SystemUsageModule
import qs.Modules.WallpaperSelector

PanelWindow {
    id: root

    required property var notificationService
    readonly property int barHeight: Constants.gamingBarHeight
    readonly property int widgetOffset: barHeight + 8
    readonly property int edgeSpacing: 8
    // The window stays mapped and only activates its content in Game Mode, so
    // entering/leaving the profile never destroys the layer surface.
    readonly property bool isActive: DisplayProfileService.gameModeActive
    readonly property bool isControlCenter: root.isActive && AppState.isWidgetOpen("controlCenter")
    readonly property bool isNotificationsCenter: root.isActive && AppState.isWidgetOpen("notificationsCenter")
    readonly property bool isDashboard: root.isActive && AppState.isWidgetOpen("dashboard")
    readonly property bool isMusic: root.isActive && AppState.isWidgetOpen("music")
    readonly property bool isCalendar: root.isActive && AppState.isWidgetOpen("calendar")
    readonly property bool isSystemUsage: root.isActive && AppState.isWidgetOpen("systemUsage")
    readonly property bool isLauncher: root.isActive && AppState.isWidgetOpen("launcher")
    readonly property bool isClipboard: root.isActive && AppState.isWidgetOpen("clipboard")
    readonly property bool isWallpaper: root.isActive && AppState.isWidgetOpen("wallpaper")
    readonly property bool isPowerMenu: root.isActive && AppState.isWidgetOpen("powerMenu")
    readonly property bool isScreenshot: root.isActive && AppState.isWidgetOpen("screenshot")
    readonly property bool isTray: root.isActive && (AppState.activeWidget || "").startsWith("systemTray_")
    readonly property bool hasAnyOpen: isControlCenter || isNotificationsCenter || isDashboard || isMusic || isCalendar || isSystemUsage || isLauncher || isClipboard || isWallpaper || isPowerMenu || isScreenshot || isTray
    readonly property bool needsFocus: isLauncher || isClipboard || isWallpaper || isPowerMenu || isScreenshot
    readonly property int activeTrayIndex: {
        let targetId = AppState.activeWidget && AppState.activeWidget.startsWith("systemTray_") ? AppState.activeWidget : "";
        if (targetId && targetId.startsWith("systemTray_")) {
            let parts = targetId.split("_");
            if (parts.length > 1) {
                let idx = parseInt(parts[1]);
                if (!isNaN(idx))
                    return idx;

            }
        }
        return -1;
    }
    readonly property var activeTrayItem: {
        if (!isTray)
            return null;

        if (AppState.activeTrayItemPinned)
            return AppState.resolvedTrayItem;

        return getTrayItem(activeTrayIndex);
    }
    readonly property string activeTrayTitle: {
        let item = activeTrayItem;
        if (!item)
            return "Menu";

        let t = item.title ? item.title.toString().trim() : "";
        if (t !== "")
            return t;

        let tt = item.tooltipTitle ? item.tooltipTitle.toString().trim() : (item.toolTipTitle ? item.toolTipTitle.toString().trim() : "");
        if (tt !== "")
            return tt;

        let id = item.id ? item.id.toString().trim() : "";
        if (id !== "" && !id.startsWith("org.kde.StatusNotifier")) {
            let clean = id.replace(/_status_icon_\d+$/i, "").replace(/[-_]/g, " ");
            return clean.charAt(0).toUpperCase() + clean.slice(1);
        }
        return "Menu";
    }
    property var _pendingFocusItem: null
    property int _focusAttempts: 0

    function getTrayItem(index) {
        if (index < 0)
            return null;

        let items = QSSysTray.SystemTray.items;
        if (!items)
            return null;

        if (items.values && index < items.values.length)
            return items.values[index];

        return null;
    }

    function resolveFocusTarget(item) {
        if (!item)
            return null;

        if (item.textField)
            return item.textField;

        return item;
    }

    function scheduleContentFocus(item) {
        let target = resolveFocusTarget(item);
        if (!target)
            return ;

        _pendingFocusItem = target;
        _focusAttempts = 0;
        focusTimer.restart();
    }

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: needsFocus ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    focusable: needsFocus
    color: "transparent"
    visible: SettingsService.settingsLoaded
    onIsLauncherChanged: {
        if (isLauncher) {
            if (launcherContent && typeof launcherContent.resetLauncher === "function")
                launcherContent.resetLauncher();

            scheduleContentFocus(launcherContent ? launcherContent.initialFocusItem : null);
        }
    }
    onIsClipboardChanged: {
        if (isClipboard) {
            if (clipboardContent && typeof clipboardContent.resetClipboard === "function")
                clipboardContent.resetClipboard();

            scheduleContentFocus(clipboardContent ? clipboardContent.initialFocusItem : null);
        }
    }
    onIsWallpaperChanged: {
        if (isWallpaper) {
            if (wallpaperContent && typeof wallpaperContent.resetWallpaperSelector === "function")
                wallpaperContent.resetWallpaperSelector();

            scheduleContentFocus(wallpaperContent ? wallpaperContent.initialFocusItem : null);
        }
    }
    onIsPowerMenuChanged: {
        if (isPowerMenu) {
            if (powerMenuContent && typeof powerMenuContent.resetPowerMenu === "function")
                powerMenuContent.resetPowerMenu();

            scheduleContentFocus(powerMenuContent ? powerMenuContent.initialFocusItem : null);
        }
    }
    onIsScreenshotChanged: {
        if (isScreenshot) {
            if (screenshotContent && typeof screenshotContent.resetScreenCapture === "function")
                screenshotContent.resetScreenCapture();

            scheduleContentFocus(screenshotContent ? screenshotContent.initialFocusItem : null);
        }
    }
    onVisibleChanged: {
        if (visible && needsFocus && _pendingFocusItem) {
            _focusAttempts = 0;
            focusTimer.restart();
        }
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    QtObject {
        id: widgetProxy

        property bool isOpen: root.hasAnyOpen
        property int cornerRadius: 0
        property real openProgress: 1
        property real bounceProgress: 1

        function close() {
            AppState.closeAllWidgets();
        }

        onIsOpenChanged: {
            if (!isOpen && root.hasAnyOpen)
                AppState.closeAllWidgets();

        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.topMargin: root.barHeight
        enabled: root.hasAnyOpen
        focus: root.needsFocus
        Keys.onEscapePressed: {
            AppState.closeAllWidgets();
        }
        onClicked: {
            AppState.closeAllWidgets();
        }
    }

    // The layer-shell surface only gets keyboard focus once it is mapped and
    // focusable, so focus must be re-applied after the window becomes active
    // (same approach used by OverlayWindow's initialFocusTimer).
    Timer {
        id: focusTimer

        interval: 30
        repeat: true
        onTriggered: {
            if (!root.needsFocus || !root.visible || !root._pendingFocusItem) {
                stop();
                return ;
            }
            if (root._pendingFocusItem.activeFocus) {
                stop();
                return ;
            }
            root._pendingFocusItem.forceActiveFocus();
            root._focusAttempts++;
            if (root._focusAttempts >= 10)
                stop();

        }
    }

    Rectangle {
        id: ccContainer

        visible: root.isControlCenter
        enabled: visible
        anchors.top: parent.top
        anchors.topMargin: root.widgetOffset
        anchors.right: parent.right
        anchors.rightMargin: root.edgeSpacing
        width: Math.min(ccContent.implicitWidth + 24, root.width - 24)
        height: Math.min(ccContent.implicitHeight + 24, root.height - 48)
        color: Theme.bg
        radius: 0
        border.width: 1
        border.color: Theme.border

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

        ControlCenterContent {
            id: ccContent

            anchors.fill: parent
            anchors.margins: Constants.sizeSm
            notificationService: root.notificationService
            widget: widgetProxy
        }

    }

    Rectangle {
        id: ncContainer

        visible: root.isNotificationsCenter
        enabled: visible
        anchors.top: parent.top
        anchors.topMargin: root.widgetOffset
        anchors.right: parent.right
        anchors.rightMargin: root.edgeSpacing
        width: Math.min(ncContent.implicitWidth + 24, root.width - 24)
        height: Math.min(ncContent.implicitHeight + 24, root.height - 48)
        color: Theme.bg
        radius: 0
        border.width: 1
        border.color: Theme.border

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

        NotificationCenter {
            id: ncContent

            anchors.fill: parent
            anchors.margins: Constants.sizeSm
            notificationService: root.notificationService
            controlCenterOpen: true
        }

    }

    Rectangle {
        id: dashboardContainer

        visible: root.isDashboard
        enabled: visible
        anchors.top: parent.top
        anchors.topMargin: root.widgetOffset
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(dashboardContent.implicitWidth + 24, root.width - 24)
        height: Math.min(dashboardContent.implicitHeight + 24, root.height - 48)
        color: Theme.bg
        radius: 0
        border.width: 1
        border.color: Theme.border

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

        DashboardContent {
            id: dashboardContent

            anchors.fill: parent
            anchors.margins: Constants.sizeSm
            widget: widgetProxy
        }

    }

    Rectangle {
        id: musicContainer

        visible: root.isMusic
        enabled: visible
        anchors.top: parent.top
        anchors.topMargin: root.widgetOffset
        anchors.right: parent.right
        anchors.rightMargin: root.edgeSpacing
        width: Math.min(musicContent.implicitWidth + 24, root.width - 24)
        height: Math.min(musicContent.implicitHeight + 24, root.height - 48)
        color: Theme.bg
        radius: 0
        border.width: 1
        border.color: Theme.border

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

        MiniMusicWidget {
            id: musicContent

            anchors.fill: parent
            anchors.margins: Constants.sizeSm
            widget: widgetProxy
        }

    }

    Rectangle {
        id: calendarContainer

        visible: root.isCalendar
        enabled: visible
        anchors.top: parent.top
        anchors.topMargin: root.widgetOffset
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(calendarContent.implicitWidth + 24, root.width - 24)
        height: Math.min(calendarContent.implicitHeight + 24, root.height - 48)
        color: Theme.bg
        radius: 0
        border.width: 1
        border.color: Theme.border

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

        CalendarWidget {
            id: calendarContent

            anchors.fill: parent
            anchors.margins: Constants.sizeSm
            widget: widgetProxy
        }

    }

    Rectangle {
        id: systemUsageContainer

        visible: root.isSystemUsage
        enabled: visible
        anchors.top: parent.top
        anchors.topMargin: root.widgetOffset
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(systemUsageContent.implicitWidth + 24, root.width - 24)
        height: Math.min(systemUsageContent.implicitHeight + 24, root.height - 48)
        color: Theme.bg
        radius: 0
        border.width: 1
        border.color: Theme.border

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

        SystemUsageModule.SystemUsageContent {
            id: systemUsageContent

            anchors.centerIn: parent
            widget: widgetProxy
        }

    }

    Rectangle {
        id: trayContainer

        visible: root.isTray
        enabled: visible
        anchors.top: parent.top
        anchors.topMargin: root.widgetOffset
        anchors.right: parent.right
        anchors.rightMargin: root.edgeSpacing
        width: Math.min(300, root.width - 24)
        height: Math.min(340, root.height - 48)
        color: Theme.bg
        radius: 0
        border.width: 1
        border.color: Theme.border

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

        TrayMenu {
            id: trayContent

            anchors.fill: parent
            anchors.margins: Constants.sizeXs
            menuHandle: (root.isTray && root.activeTrayItem) ? root.activeTrayItem.menu : null
            title: root.activeTrayTitle
            onBackRequested: {
                if (AppState.activeWidget !== "")
                    AppState.closeWidget(AppState.activeWidget);

            }
            onCloseRequested: {
                if (AppState.activeWidget !== "")
                    AppState.closeWidget(AppState.activeWidget);

            }
        }

    }

    Rectangle {
        id: launcherContainer

        visible: root.isLauncher
        enabled: visible
        anchors.centerIn: parent
        width: Math.min(launcherContent.implicitWidth + 32, root.width - 40)
        height: Math.min(launcherContent.implicitHeight + 32, root.height - 40)
        color: Theme.bg
        radius: 0
        border.width: 1
        border.color: Theme.border

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

        LauncherContent {
            id: launcherContent

            anchors.fill: parent
            anchors.margins: Constants.sizeLg
            widget: widgetProxy
        }

    }

    Rectangle {
        id: clipboardContainer

        visible: root.isClipboard
        enabled: visible
        anchors.centerIn: parent
        width: Math.min(clipboardContent.implicitWidth + 32, root.width - 40)
        height: Math.min(clipboardContent.implicitHeight + 32, root.height - 40)
        color: Theme.bg
        radius: 0
        border.width: 1
        border.color: Theme.border

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

        ClipboardContent {
            id: clipboardContent

            anchors.fill: parent
            anchors.margins: Constants.sizeLg
            widget: widgetProxy
        }

    }

    Rectangle {
        id: wallpaperContainer

        visible: root.isWallpaper
        enabled: visible
        anchors.centerIn: parent
        width: Math.min(wallpaperContent.implicitWidth + 32, root.width - 40)
        height: Math.min(wallpaperContent.implicitHeight + 32, root.height - 40)
        color: Theme.bg
        radius: 0
        border.width: 1
        border.color: Theme.border

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

        WallpaperSelectorContent {
            id: wallpaperContent

            anchors.fill: parent
            anchors.margins: Constants.sizeLg
            widget: widgetProxy
        }

    }

    Rectangle {
        id: powerMenuContainer

        visible: root.isPowerMenu
        enabled: visible
        anchors.centerIn: parent
        width: powerMenuContent.implicitWidth
        height: powerMenuContent.implicitHeight
        color: Theme.bg
        radius: 0
        border.width: 1
        border.color: Theme.border
        Keys.onEscapePressed: function(event) {
            AppState.closeAllWidgets();
            event.accepted = true;
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

        PowerMenuContent {
            id: powerMenuContent

            anchors.centerIn: parent
            widget: widgetProxy
        }

    }

    Rectangle {
        id: screenshotContainer

        visible: root.isScreenshot
        enabled: visible
        anchors.centerIn: parent
        width: screenshotContent.implicitWidth
        height: screenshotContent.implicitHeight
        color: Theme.bg
        radius: 0
        border.width: 1
        border.color: Theme.border

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

        ScreenCaptureContent {
            id: screenshotContent

            anchors.centerIn: parent
            widget: widgetProxy
        }

    }

    mask: Region {
        Region {
            x: 0
            y: root.barHeight
            width: root.hasAnyOpen ? root.width : 0
            height: root.hasAnyOpen ? Math.max(0, root.height - root.barHeight) : 0
        }

    }

}
