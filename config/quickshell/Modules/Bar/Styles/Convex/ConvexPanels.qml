import QtQuick
import Quickshell
import Quickshell.Io
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Clipboard
import qs.Modules.Launcher
import qs.Modules.PowerMenu
import qs.Modules.ScreenCapture
import qs.Modules.WallpaperSelector

Item {
    id: root

    required property int barHeight
    required property int bezelSize
    required property var notificationService
    readonly property bool hasAnyDrawerOpen: (bottomDrawerLauncher.isOpen) || (bottomDrawerClipboard.isOpen) || (bottomDrawerWallpaper.isOpen) || (bottomDrawerPower.isOpen) || (bottomDrawerScreenshot.isOpen)
    readonly property bool isConvexPopupOpen: SettingsService.barConvexMode && (AppState.isPopupOpen("music") || AppState.isPopupOpen("notificationsCenter"))

    anchors.fill: parent

    // Click outside to close any open popups
    MouseArea {
        anchors.fill: parent
        enabled: root.hasAnyDrawerOpen || root.isConvexPopupOpen
        onClicked: {
            AppState.closeAllPopups();
        }
    }

    // Bottom Drawer: Launcher
    ConvexDrawer {
        id: bottomDrawerLauncher

        popupId: "launcher"
        edge: Qt.BottomEdge
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.bezelSize

        sourceComponent: Component {
            LauncherContent {
                widget: bottomDrawerLauncher
            }

        }

    }

    // Bottom Drawer: Clipboard
    ConvexDrawer {
        id: bottomDrawerClipboard

        popupId: "clipboard"
        edge: Qt.BottomEdge
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.bezelSize

        sourceComponent: Component {
            ClipboardContent {
                widget: bottomDrawerClipboard
            }

        }

    }

    // Bottom Drawer: Wallpaper Selector
    ConvexDrawer {
        id: bottomDrawerWallpaper

        popupId: "wallpaper"
        edge: Qt.BottomEdge
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.bezelSize

        sourceComponent: Component {
            WallpaperSelectorContent {
                widget: bottomDrawerWallpaper
            }

        }

    }

    // Bottom Drawer: Power Menu
    ConvexDrawer {
        id: bottomDrawerPower

        popupId: "powerMenu"
        edge: Qt.BottomEdge
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.bezelSize
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
    ConvexDrawer {
        id: bottomDrawerScreenshot

        popupId: "screenshot"
        edge: Qt.BottomEdge
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.bezelSize
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
