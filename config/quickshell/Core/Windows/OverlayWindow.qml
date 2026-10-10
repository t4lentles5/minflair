import "OverlayStyles"
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Core
import qs.Core.Components
import qs.Core.Services

PanelWindow {
    // Handover is handled internally by the style, it will signal when done

    id: root

    property var notificationService: null
    property string widgetId: ""
    property bool isOpen: false
    property Item initialFocusItem: null
    property bool exclusive: true
    // We bind the external content to our inner content holder
    default property alias content: innerContentHolder.data
    property int animationDuration: HyprlandService.enableAnimations ? Constants.animSlow : 0
    readonly property int closeDuration: HyprlandService.enableAnimations ? Constants.animNormal : 0
    property int fadeDuration: HyprlandService.enableAnimations ? Constants.animNormal : 0
    property color backgroundColor: Theme.bg
    property int preferredWidth: (innerContentHolder.children.length > 0 && innerContentHolder.children[0].implicitWidth > 0) ? (innerContentHolder.children[0].implicitWidth + contentPadding * 2) : 600
    property int preferredHeight: (innerContentHolder.children.length > 0 && innerContentHolder.children[0].implicitHeight > 0) ? (innerContentHolder.children[0].implicitHeight + contentPadding * 2) : 500
    property real smoothPreferredWidth: preferredWidth
    property real smoothPreferredHeight: preferredHeight
    property bool positionAtBottom: false
    property bool _windowVisible: false
    property bool forceVisible: false
    property int contentPadding: Constants.sizeLg
    property int windowRadius: Constants.size3Xl
    property bool enableShadow: false
    property real smoothWindowRadius: windowRadius
    property real smoothContentPadding: contentPadding
    property real openProgress: root.isOpen ? 1 : 0
    property real bounceProgress: root.isOpen ? 1 : 0
    property bool windowFocusable: true
    // Determine the active style mode cleanly
    readonly property string activeStyle: {
        if (SettingsService.barIslandMode && !positionAtBottom)
            return "island";

        return "floating";
    }
    readonly property bool isIsland: activeStyle === "island"
    readonly property bool isFloating: activeStyle === "floating"

    signal widgetOpened()
    signal widgetClosed()
    signal fullyClosed()

    function finishClosing() {
        closeDelayTimer.stop();
        if (styleLoader.item && styleLoader.item.isHandover !== undefined && styleLoader.item.isHandover) {
        } else {
            root._windowVisible = false;
            root.fullyClosed();
        }
    }

    function close() {
        isOpen = false;
    }

    surfaceFormat.opaque: false
    color: "transparent"
    focusable: root.isOpen && root.windowFocusable
    exclusionMode: ExclusionMode.Ignore
    visible: _windowVisible || forceVisible || (styleLoader.item && styleLoader.item.isHandover)
    onIsOpenChanged: {
        if (widgetId === "")
            return ;

        if (isOpen) {
            closeDelayTimer.stop();
            if (exclusive && !AppState.isWidgetOpen(widgetId))
                AppState.openWidget(widgetId);

            _windowVisible = true;
            root.widgetOpened();
            if (root.initialFocusItem)
                initialFocusTimer.start();

        } else {
            let anotherFocusOpen = AppState.isFocusWidgetOpen && !AppState.isWidgetOpen(widgetId);
            if (exclusive && anotherFocusOpen) {
                closeDelayTimer.stop();
                _windowVisible = false;
                root.widgetClosed();
                root.fullyClosed();
            } else {
                closeDelayTimer.start();
                root.widgetClosed();
            }
        }
    }
    onInitialFocusItemChanged: {
        if (isOpen && windowFocusable && initialFocusItem)
            initialFocusTimer.restart();

    }
    onWindowFocusableChanged: {
        if (isOpen && windowFocusable && initialFocusItem)
            initialFocusTimer.restart();

    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        enabled: root.isOpen
        onClicked: root.isOpen = false
    }

    Timer {
        id: closeDelayTimer

        interval: HyprlandService.enableAnimations ? (root.isIsland ? (Constants.animNormal + 80) : (Constants.animSlow + 150)) : 10
        repeat: false
        onTriggered: {
            if (exclusive && AppState.isWidgetOpen(widgetId))
                AppState.closeWidget(widgetId);

            root.finishClosing();
        }
    }

    Timer {
        id: initialFocusTimer

        interval: 30
        repeat: false
        onTriggered: {
            if (root.windowFocusable && root.initialFocusItem) {
                if (root.initialFocusItem.textField)
                    root.initialFocusItem.textField.forceActiveFocus();
                else
                    root.initialFocusItem.forceActiveFocus();
            }
        }
    }

    Loader {
        id: styleLoader

        anchors.fill: parent
        sourceComponent: {
            switch (root.activeStyle) {
            case "island":
                return islandComponent;
            case "floating":
            default:
                return floatingComponent;
            }
        }
        onStatusChanged: {
            if (status === Loader.Ready && root.isOpen)
                initialFocusTimer.restart();

        }
    }

    // The inner holder automatically anchors inside the active style's content slot
    Item {
        id: innerContentHolder

        parent: styleLoader.item ? styleLoader.item.contentSlot : root
        anchors.fill: parent
        visible: styleLoader.item !== null
        // Forward keys to the focused item
        Keys.forwardTo: (root.windowFocusable && root.initialFocusItem) ? [root.initialFocusItem] : []
        Keys.enabled: root.isOpen && root.windowFocusable
        Keys.onEscapePressed: {
            if (root.windowFocusable)
                root.isOpen = false;

        }
    }

    Component {
        id: floatingComponent

        FloatingOverlayStyle {
            widget: root
        }

    }

    Component {
        id: islandComponent

        IslandOverlayStyle {
            widget: root
        }

    }

    mask: Region {
        Region {
            x: (root.isOpen && root.windowFocusable) ? 0 : ((root._windowVisible || (styleLoader.item && styleLoader.item.isHandover)) ? (styleLoader.item ? styleLoader.item.container.x : 0) : 0)
            y: (root.isOpen && root.windowFocusable) ? 0 : ((root._windowVisible || (styleLoader.item && styleLoader.item.isHandover)) ? (styleLoader.item ? styleLoader.item.container.y : 0) : 0)
            width: (root.isOpen && root.windowFocusable) ? root.width : ((root._windowVisible || (styleLoader.item && styleLoader.item.isHandover)) ? (styleLoader.item ? styleLoader.item.container.width : 0) : 0)
            height: (root.isOpen && root.windowFocusable) ? root.height : ((root._windowVisible || (styleLoader.item && styleLoader.item.isHandover)) ? (styleLoader.item ? styleLoader.item.container.height : 0) : 0)
        }

    }

    Behavior on smoothPreferredWidth {
        enabled: HyprlandService.enableAnimations && (root.isIsland || (root.isOpen && root.bounceProgress >= 0.95))

        NumberAnimation {
            duration: Constants.animNormal
            easing.type: root.isOpen ? Easing.OutQuint : Easing.OutCubic
            onRunningChanged: {
                if (!running && !root.isOpen && root.isIsland)
                    root.finishClosing();

            }
        }

    }

    Behavior on smoothPreferredHeight {
        enabled: HyprlandService.enableAnimations && (root.isIsland || (root.isOpen && root.bounceProgress >= 0.95))

        NumberAnimation {
            duration: Constants.animNormal
            easing.type: root.isOpen ? Easing.OutQuint : Easing.OutCubic
        }

    }

    Behavior on smoothWindowRadius {
        enabled: HyprlandService.enableAnimations && (root.isIsland || (root.isOpen && root.bounceProgress >= 0.95))

        NumberAnimation {
            duration: Constants.animNormal
            easing.type: root.isOpen ? Easing.OutQuint : Easing.OutCubic
        }

    }

    Behavior on smoothContentPadding {
        enabled: HyprlandService.enableAnimations && (root.isIsland || (root.isOpen && root.bounceProgress >= 0.95))

        NumberAnimation {
            duration: Constants.animNormal
            easing.type: root.isOpen ? Easing.OutQuint : Easing.OutCubic
        }

    }

    Behavior on openProgress {
        enabled: HyprlandService.enableAnimations

        NumberAnimation {
            duration: root.isOpen ? root.fadeDuration : root.closeDuration
            easing.type: root.isOpen ? Easing.OutCubic : Easing.InCubic
        }

    }

    Behavior on bounceProgress {
        enabled: HyprlandService.enableAnimations

        NumberAnimation {
            duration: root.isOpen ? ((root.isIsland && AppState.hasActiveNotification) ? Constants.animSlow : (root.isIsland ? Constants.animExpressive : Constants.animNormal)) : Constants.animNormal
            easing.type: root.isIsland ? (root.isOpen ? Easing.OutQuint : Easing.OutCubic) : (root.isOpen ? Easing.OutCubic : Easing.InCubic)
        }

    }

}
