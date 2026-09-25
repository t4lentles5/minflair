import QtQuick
import Quickshell
import Quickshell.Io
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Bar.Widgets.Dashboard
import qs.Modules.Clipboard
import qs.Modules.ControlCenter
import qs.Modules.Launcher
import qs.Modules.MusicPopup
import qs.Modules.PowerMenu
import qs.Modules.ScreenCapture
import qs.Modules.WallpaperSelector

Item {
    id: root

    required property int barHeight
    required property int bezelSize
    required property var notificationService

    anchors.fill: parent

    // Click outside to close any open popups
    MouseArea {
        anchors.fill: parent
        enabled: AppState.hasAnyPopupOpen
        onClicked: {
            AppState.closeAllPopups();
        }
    }

    // Top Drawer: Dashboard
    FramedDrawer {
        id: topDrawerDashboard

        popupId: "dashboard"
        isOpen: SettingsService.barFramedMode && AppState.isPopupOpen("dashboard") && !AppState.isPopupOpen("music")
        edge: Qt.TopEdge
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: root.barHeight

        sourceComponent: Component {
            DashboardContent {
                isVertical: false
            }

        }

    }

    // Top Drawer: Music
    FramedDrawer {
        id: topDrawerMusic

        popupId: "music"
        isOpen: SettingsService.barFramedMode && AppState.isPopupOpen("music") && !AppState.isPopupOpen("dashboard")
        edge: Qt.TopEdge
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: root.barHeight

        sourceComponent: Component {
            MiniMusicWidget {
                // Width/height will be determined by implicit/preferred size

            }

        }

    }

    // Right Drawer: Control Center
    FramedDrawer {
        id: rightDrawerControlCenter

        popupId: "controlCenter"
        isOpen: SettingsService.barFramedMode && AppState.isPopupOpen("controlCenter")
        edge: Qt.RightEdge
        anchors.right: parent.right
        anchors.rightMargin: root.bezelSize
        anchors.top: parent.top
        anchors.topMargin: root.barHeight
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.bezelSize
        cornerRadius: Constants.size4Xl

        sourceComponent: Component {
            ControlCenterContent {
                // Wrapping the content inside a Flickable might be necessary if it's taller than screen
                // but ControlCenterContent might already have one. Let's see later.

                notificationService: root.notificationService
                isHorizontal: false
            }

        }

    }

    // Bottom Drawer: Launcher
    FramedDrawer {
        id: bottomDrawerLauncher

        popupId: "launcher"
        edge: Qt.BottomEdge
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.bezelSize
        customWidth: 720
        customHeight: 480

        sourceComponent: Component {
            LauncherContent {
            }

        }

    }

    // Bottom Drawer: Clipboard
    FramedDrawer {
        id: bottomDrawerClipboard

        popupId: "clipboard"
        edge: Qt.BottomEdge
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.bezelSize
        customWidth: 720
        customHeight: 480

        sourceComponent: Component {
            ClipboardContent {
            }

        }

    }

    // Bottom Drawer: Wallpaper Selector
    FramedDrawer {
        id: bottomDrawerWallpaper

        popupId: "wallpaper"
        edge: Qt.BottomEdge
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.bezelSize
        customWidth: Math.min(1008, root.width - 2 * root.bezelSize - 64)
        customHeight: 216

        sourceComponent: Component {
            WallpaperSelectorContent {
            }

        }

    }

    // Bottom Drawer: Power Menu
    FramedDrawer {
        id: bottomDrawerPower

        popupId: "powerMenu"
        edge: Qt.BottomEdge
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.bezelSize
        customWidth: 320
        customHeight: 48
        contentPadding: 0
        safeMarginX: cornerRadius * 2
        safeMarginY: 0
        cornerRadius: Constants.sizeMd

        sourceComponent: Component {
            PowerMenuContent {
                widget: bottomDrawerPower
            }

        }

    }

    // Bottom Drawer: Screen Capture
    FramedDrawer {
        id: bottomDrawerScreenshot

        popupId: "screenshot"
        edge: Qt.BottomEdge
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.bezelSize
        customWidth: 448
        customHeight: 48
        contentPadding: 0
        safeMarginX: cornerRadius * 2
        safeMarginY: 0
        cornerRadius: Constants.sizeMd

        sourceComponent: Component {
            ScreenCaptureContent {
                widget: bottomDrawerScreenshot
            }

        }

    }

}
