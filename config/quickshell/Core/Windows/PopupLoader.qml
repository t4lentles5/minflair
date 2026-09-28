import QtQuick
import Quickshell
import Quickshell.Io
import qs.Core.Components
import qs.Core.Services

Item {
    id: root

    property string popupId: ""
    property Component sourceComponent
    property bool enabled: true
    property bool exclusive: true
    property bool _isInternalActive: false
    readonly property bool isIslandHandled: SettingsService.barIslandMode && (popupId === "dashboard" || popupId === "controlCenter" || popupId === "music" || popupId === "launcher" || popupId === "clipboard" || popupId === "wallpaper")
    readonly property bool isConvexHandled: SettingsService.barConvexMode && popupId === "music"
    readonly property bool isNotchHandled: SettingsService.barNotchMode && (popupId === "dashboard" || popupId === "controlCenter" || popupId === "music" || popupId === "launcher" || popupId === "clipboard" || popupId === "wallpaper")
    readonly property bool isFramedHandled: (SettingsService.barFramedMode && (popupId === "dashboard" || popupId === "controlCenter" || popupId === "music" || popupId === "launcher" || popupId === "powerMenu" || popupId === "clipboard" || popupId === "wallpaper" || popupId === "screenshot")) || (SettingsService.barConvexMode && (popupId === "music" || popupId === "launcher" || popupId === "powerMenu" || popupId === "clipboard" || popupId === "wallpaper" || popupId === "screenshot"))
    readonly property bool shouldLoadWindow: enabled && !isIslandHandled && !isNotchHandled && !isConvexHandled && !isFramedHandled
    readonly property bool _isActive: shouldLoadWindow && (exclusive ? AppState.isPopupOpen(popupId) : _isInternalActive)
    property bool _isClosing: false
    property alias item: loader.item

    on_IsActiveChanged: {
        if (popupId === "")
            return ;

        if (_isActive) {
            _isClosing = false;
            loader.active = true;
            if (loader.status === Loader.Ready && loader.item)
                loader.item.isOpen = true;

        } else {
            if (loader.item)
                loader.item.isOpen = false;

            _isClosing = true;
        }
    }
    Component.onCompleted: {
        if (AppState.socketsCleaned && root.popupId !== "")
            server.active = true;

    }

    Connections {
        function onSocketsCleanedChanged() {
            if (AppState.socketsCleaned && root.popupId !== "")
                server.active = true;

        }

        target: AppState
    }

    Connections {
        function onTogglePopup(id) {
            if (root.popupId !== "" && id === root.popupId)
                root._isInternalActive = !root._isInternalActive;

        }

        function onOpenPopup(id) {
            if (root.popupId !== "" && id === root.popupId)
                root._isInternalActive = true;

        }

        target: AppState
        enabled: root.enabled && !root.exclusive && root.shouldLoadWindow
    }

    Loader {
        id: loader

        anchors.fill: parent
        active: false
        sourceComponent: root.sourceComponent
        onStatusChanged: {
            if (status === Loader.Ready && root._isActive && item)
                item.isOpen = true;

        }

        Connections {
            function onFullyClosed() {
                loader.active = false;
                root._isClosing = false;
                if (!root.exclusive)
                    root._isInternalActive = false;

                AppState.closePopup(root.popupId);
            }

            target: loader.item
            ignoreUnknownSignals: true
        }

    }

    SocketServer {
        id: server

        path: root.popupId !== "" ? "/tmp/quickshell_" + root.popupId : ""
        active: false

        handler: Component {
            Socket {
                onConnectedChanged: {
                    if (connected) {
                        AppState.togglePopup(root.popupId);
                        connected = false;
                    }
                }
            }

        }

    }

}
