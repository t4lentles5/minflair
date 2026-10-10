import QtQuick
import Quickshell
import Quickshell.Io
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Bar.Styles.Convex
import qs.Modules.Dashboard

Item {
    id: root

    required property int barHeight
    required property int bezelSize
    required property var notificationService
    property alias dashboardWidget: sidebarDashboard
    property alias controlCenterWidget: rightHost.controlCenterWidget
    property alias notificationsCenterWidget: rightHost.notificationsCenterWidget
    property alias activeTrayMenu: rightHost.activeTrayMenu
    readonly property bool hasAnySidebarOpen: (sidebarDashboard && (sidebarDashboard.isOpen || sidebarDashboard._visible)) || (rightHost && (rightHost.isOpen || rightHost._visible))
    readonly property bool hasAnyDrawerOpen: bottomDrawer && (bottomDrawer.isOpen || bottomDrawer._visible)
    readonly property bool hasAnyPanelOpen: hasAnyDrawerOpen || hasAnySidebarOpen
    readonly property bool isConvexCenterOpen: SettingsService.barConvexMode && AppState.isWidgetOpen("music")

    anchors.fill: parent

    // Click outside to close any open panels/drawers
    MouseArea {
        anchors.fill: parent
        enabled: root.hasAnyPanelOpen || root.isConvexCenterOpen
        onClicked: {
            AppState.closeAllWidgets();
        }
    }

    // Left Sidebar: Dashboard
    Dashboard {
        id: sidebarDashboard

        anchors.fill: parent
        isOpen: AppState.isWidgetOpen("dashboard")
    }

    // Unified Right Sidebar: Control Center, Notification Center & System Tray
    ConvexRightHost {
        id: rightHost

        anchors.fill: parent
        notificationService: root.notificationService
    }

    // Unified Bottom Drawer: Launcher, Clipboard, Wallpaper, Power Menu & Screen Capture
    ConvexBottomHost {
        id: bottomDrawer

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.bezelSize
    }

}
