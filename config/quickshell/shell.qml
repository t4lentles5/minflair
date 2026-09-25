import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Core
import qs.Core.Services
import qs.Core.Windows
import qs.Modules.Bar
import qs.Modules.Bar.Styles.Framed

ShellRoot {
    id: root

    readonly property bool isFramed: SettingsService.barStyle === "framed" || SettingsService.barStyle === "convex"

    Process {
        id: globalSocketCleanup

        command: ["sh", "-c", "rm -f /tmp/quickshell_*"]
        running: true
        onExited: AppState.socketsCleaned = true
    }

    NotificationService {
        id: globalNotificationService
    }

    PanelWindow {
        id: barSurface

        readonly property int barHeight: BarStyleConfig.barHeight(SettingsService.barStyle)
        readonly property int barMarginTop: BarStyleConfig.barMarginTop(SettingsService.barStyle)
        readonly property int barMarginSide: BarStyleConfig.barMarginSide(SettingsService.barStyle)
        readonly property int popupStartY: barMarginTop + barHeight

        WlrLayershell.layer: WlrLayer.Top
        color: "transparent"
        focusable: false
        implicitHeight: !SettingsService.settingsLoaded ? 0 : (SettingsService.barStyle === "notch" ? 40 : (barMarginTop + barHeight))
        visible: SettingsService.settingsLoaded

        anchors {
            top: true
            left: true
            right: true
        }

        mask: Region {
        }

    }

    BarOverlayWindow {
        id: popupSurface

        notificationService: globalNotificationService
        barSurface: barSurface
        visible: SettingsService.settingsLoaded && !root.isFramed
    }

    FramedDesktop {
        id: framedDesktopSurface

        notificationService: globalNotificationService
        visible: SettingsService.settingsLoaded && root.isFramed
    }

    GlobalPopups {
        id: globalPopups
    }

}
