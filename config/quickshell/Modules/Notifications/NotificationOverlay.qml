import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Core
import qs.Core.Components
import qs.Core.Services

Item {
    id: root

    required property var notificationService
    readonly property bool hasActiveNotifications: loader.item ? loader.item.hasActiveNotifications : false
    readonly property bool isOpen: loader.item ? (loader.item.isOpen !== undefined ? loader.item.isOpen : hasActiveNotifications) : false
    readonly property real blockX: loader.item ? (loader.item.blockX !== undefined ? loader.item.blockX : (loader.item.blockContainer ? loader.item.blockContainer.x : 0)) : 0
    readonly property real blockY: loader.item ? (loader.item.blockY !== undefined ? loader.item.blockY : (loader.item.blockContainer ? loader.item.blockContainer.y : 0)) : 0
    readonly property real blockWidth: loader.item ? (loader.item.blockWidth !== undefined ? loader.item.blockWidth : (loader.item.blockContainer ? loader.item.blockContainer.width : 0)) : 0
    readonly property real blockHeight: loader.item ? (loader.item.blockHeight !== undefined ? loader.item.blockHeight : (loader.item.blockContainer ? loader.item.blockContainer.height : 0)) : 0

    Loader {
        id: loader

        anchors.fill: parent
        sourceComponent: (SettingsService.barNotchMode || SettingsService.barConvexMode) ? notchComponent : (SettingsService.barIslandMode ? islandComponent : (SettingsService.barFramedMode ? framedComponent : minflairComponent))
    }

    Component {
        id: notchComponent

        Item {
            property bool hasActiveNotifications: false
            property var blockContainer: null
        }

    }

    Component {
        id: islandComponent

        Item {
            property bool hasActiveNotifications: false
            property var blockContainer: null
        }

    }

    Component {
        id: framedComponent

        FramedNotificationOverlay {
            notificationService: root.notificationService
        }

    }

    Component {
        id: minflairComponent

        MinflairNotificationOverlay {
            notificationService: root.notificationService
        }

    }

}
