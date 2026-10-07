import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Core
import qs.Core.Services
import qs.Modules.Bar.Widgets.Clock as ClockModule
import qs.Modules.Clipboard as ClipboardModule
import qs.Modules.ControlCenter as ControlCenterModule
import qs.Modules.Dashboard as DashboardModule
import qs.Modules.Launcher as LauncherModule
import qs.Modules.Music as MusicModule
import qs.Modules.NotificationCenter as NotificationCenterModule
import qs.Modules.PowerMenu as PowerMenuModule
import qs.Modules.ScreenCapture as ScreenCaptureModule
import qs.Modules.WallpaperSelector as WallpaperModule

Item {
    id: root

    required property var islandBar
    required property var notificationService

    function getTargetPadding(panel) {
        if (panel === "")
            return 0;

        if (panel === "screenshot" || panel === "powerMenu")
            return Constants.sizeSm;

        return Constants.sizeLg;
    }

    function getTargetWidth(panel, item, idleContentW) {
        let pad = getTargetPadding(panel);
        if (item && item.implicitWidth > 0)
            return item.implicitWidth + (pad * 2);

        let w = Math.round(idleContentW) + 24;
        return (w % 2 === 0) ? w : (w + 1);
    }

    function getTargetHeight(panel, item) {
        let pad = getTargetPadding(panel);
        if (item && item.implicitHeight > 0)
            return item.implicitHeight + (pad * 2);

        return 36;
    }

    function getContentWidth(panel, item) {
        let pad = getTargetPadding(panel);
        return Math.max(0, getTargetWidth(panel, item, 0) - (pad * 2));
    }

    function getContentHeight(panel, item) {
        let pad = getTargetPadding(panel);
        return Math.max(0, getTargetHeight(panel, item) - (pad * 2));
    }

    function getTargetRadius(panel) {
        if (panel === "")
            return getTargetHeight("", null) / 2;

        if (panel === "screenshot" || panel === "powerMenu") {
            let optionRadius = Constants.sizeSm;
            return optionRadius + getTargetPadding(panel);
        }
        return Constants.size3Xl;
    }

    function getComponent(panelName) {
        switch (panelName) {
        case "clock":
            return clockComp;
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
        case "screenshot":
            return screenshotComp;
        case "powerMenu":
            return powerMenuComp;
        default:
            return null;
        }
    }

    Component {
        id: clockComp

        ClockModule.ClockContent {
            widget: root.islandBar
        }

    }

    Component {
        id: dashboardComp

        DashboardModule.DashboardContent {
            widget: root.islandBar
        }

    }

    Component {
        id: controlCenterComp

        ControlCenterModule.ControlCenterContent {
            widget: root.islandBar
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
            widget: root.islandBar
        }

    }

    Component {
        id: launcherComp

        LauncherModule.LauncherContent {
            widget: root.islandBar
        }

    }

    Component {
        id: clipboardComp

        ClipboardModule.ClipboardContent {
            widget: root.islandBar
        }

    }

    Component {
        id: wallpaperComp

        WallpaperModule.WallpaperSelectorContent {
            widget: root.islandBar
        }

    }

    Component {
        id: screenshotComp

        ScreenCaptureModule.ScreenCaptureContent {
            widget: root.islandBar
        }

    }

    Component {
        id: powerMenuComp

        PowerMenuModule.PowerMenuContent {
            widget: root.islandBar
        }

    }

}
