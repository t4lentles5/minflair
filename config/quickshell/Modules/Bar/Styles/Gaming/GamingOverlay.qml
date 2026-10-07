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
import qs.Modules.Clipboard
import qs.Modules.ControlCenter
import qs.Modules.Dashboard
import qs.Modules.Launcher
import qs.Modules.Music
import qs.Modules.NotificationCenter
import qs.Modules.PowerMenu
import qs.Modules.ScreenCapture
import qs.Modules.WallpaperSelector

PanelWindow {
    id: root

    required property var notificationService
    readonly property bool isControlCenter: AppState.isWidgetOpen("controlCenter")
    readonly property bool isNotificationsCenter: AppState.isWidgetOpen("notificationsCenter")
    readonly property bool isDashboard: AppState.isWidgetOpen("dashboard")
    readonly property bool isMusic: AppState.isWidgetOpen("music")
    readonly property bool isLauncher: AppState.isWidgetOpen("launcher")
    readonly property bool isClipboard: AppState.isWidgetOpen("clipboard")
    readonly property bool isWallpaper: AppState.isWidgetOpen("wallpaper")
    readonly property bool isPowerMenu: AppState.isWidgetOpen("powerMenu")
    readonly property bool isScreenshot: AppState.isWidgetOpen("screenshot")
    readonly property bool isTray: (AppState.activeWidget || "").startsWith("systemTray_")
    readonly property bool hasAnyOpen: isControlCenter || isNotificationsCenter || isDashboard || isMusic || isLauncher || isClipboard || isWallpaper || isPowerMenu || isScreenshot || isTray
    readonly property bool needsFocus: isLauncher || isClipboard || isWallpaper
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

        if (AppState.activeTrayItem)
            return AppState.activeTrayItem;

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

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: needsFocus ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    focusable: needsFocus
    color: "transparent"
    visible: SettingsService.settingsLoaded && DisplayProfileService.gameModeActive && root.hasAnyOpen
    onIsLauncherChanged: {
        if (isLauncher) {
            if (launcherContent && typeof launcherContent.resetLauncher === "function")
                launcherContent.resetLauncher();

            if (launcherContent && launcherContent.initialFocusItem)
                launcherContent.initialFocusItem.forceActiveFocus();

        }
    }
    onIsClipboardChanged: {
        if (isClipboard) {
            if (clipboardContent && typeof clipboardContent.resetClipboard === "function")
                clipboardContent.resetClipboard();

            if (clipboardContent && clipboardContent.initialFocusItem)
                clipboardContent.initialFocusItem.forceActiveFocus();

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
        anchors.topMargin: 34
        enabled: root.hasAnyOpen
        onClicked: {
            AppState.closeAllWidgets();
        }
    }

    Rectangle {
        id: ccContainer

        visible: root.isControlCenter
        anchors.top: parent.top
        anchors.topMargin: 34
        anchors.right: parent.right
        anchors.rightMargin: 12
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
            anchors.margins: 12
            notificationService: root.notificationService
            widget: widgetProxy
        }

    }

    Rectangle {
        id: ncContainer

        visible: root.isNotificationsCenter
        anchors.top: parent.top
        anchors.topMargin: 34
        anchors.right: parent.right
        anchors.rightMargin: 12
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
            anchors.margins: 12
            notificationService: root.notificationService
            controlCenterOpen: true
        }

    }

    Rectangle {
        id: dashboardContainer

        visible: root.isDashboard
        anchors.top: parent.top
        anchors.topMargin: 34
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
            anchors.margins: 12
            widget: widgetProxy
        }

    }

    Rectangle {
        id: musicContainer

        visible: root.isMusic
        anchors.top: parent.top
        anchors.topMargin: 34
        anchors.right: parent.right
        anchors.rightMargin: 12
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
            anchors.margins: 12
            widget: widgetProxy
        }

    }

    Rectangle {
        id: trayContainer

        visible: root.isTray
        anchors.top: parent.top
        anchors.topMargin: 34
        anchors.right: parent.right
        anchors.rightMargin: 12
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
            anchors.margins: 8
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
        anchors.centerIn: parent
        width: powerMenuContent.implicitWidth + 24
        height: powerMenuContent.implicitHeight + 24
        color: Theme.bg
        radius: 0
        border.width: 1
        border.color: Theme.border

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
        anchors.centerIn: parent
        width: screenshotContent.implicitWidth + 24
        height: screenshotContent.implicitHeight + 24
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
            y: 34
            width: root.hasAnyOpen ? root.width : 0
            height: root.hasAnyOpen ? Math.max(0, root.height - 34) : 0
        }

    }

}
