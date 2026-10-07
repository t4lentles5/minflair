import QtQuick
import Quickshell
import Quickshell.Io
import qs.Core.Components
import qs.Core.Services

Item {
    id: root

    property string widgetId: ""
    property Component sourceComponent
    property bool enabled: true
    property bool exclusive: true
    property bool _isInternalActive: false
    readonly property bool isBarOverlayHandled: AppState.isBarOverlayWidget(widgetId)
    readonly property bool isIslandHandled: !DisplayProfileService.gameModeActive && SettingsService.barIslandMode && isBarOverlayHandled
    readonly property bool isConvexHandled: !DisplayProfileService.gameModeActive && SettingsService.barConvexMode && isBarOverlayHandled
    readonly property bool isGamingHandled: DisplayProfileService.gameModeActive && isBarOverlayHandled
    readonly property bool shouldLoadWindow: enabled && !isIslandHandled && !isConvexHandled && !isGamingHandled
    readonly property bool _isActive: shouldLoadWindow && (exclusive ? AppState.isWidgetOpen(widgetId) : _isInternalActive)
    property bool _isClosing: false
    property alias item: loader.item

    on_IsActiveChanged: {
        if (widgetId === "")
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
        if (AppState.socketsCleaned && root.widgetId !== "")
            server.active = true;

    }

    Connections {
        function onSocketsCleanedChanged() {
            if (AppState.socketsCleaned && root.widgetId !== "")
                server.active = true;

        }

        target: AppState
    }

    Connections {
        function onToggleWidget(id) {
            if (root.widgetId !== "" && id === root.widgetId)
                root._isInternalActive = !root._isInternalActive;

        }

        function onOpenWidget(id) {
            if (root.widgetId !== "" && id === root.widgetId)
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

                AppState.closeWidget(root.widgetId);
            }

            target: loader.item
            ignoreUnknownSignals: true
        }

    }

    SocketServer {
        id: server

        path: root.widgetId !== "" ? "/tmp/quickshell_" + root.widgetId : ""
        active: false

        handler: Component {
            Socket {
                onConnectedChanged: {
                    if (connected) {
                        AppState.toggleWidget(root.widgetId);
                        connected = false;
                    }
                }
            }

        }

    }

}
