import QtQuick
import Quickshell
import qs.Core
import qs.Core.Components
import qs.Core.Services

Item {
    id: root

    property string popupId: ""
    property int edge: Qt.TopEdge // Qt.TopEdge, Qt.RightEdge, Qt.BottomEdge, Qt.LeftEdge
    property bool isOpen: AppState.isPopupOpen(popupId)
    property Component sourceComponent
    readonly property bool isTop: edge === Qt.TopEdge
    readonly property bool isRight: edge === Qt.RightEdge
    readonly property bool isBottom: edge === Qt.BottomEdge
    readonly property bool isLeft: edge === Qt.LeftEdge
    property int cornerRadius: Constants.sizeLg * 2
    property int contentPadding: Constants.sizeLg
    property color backgroundColor: Theme.bg
    property bool _visible: false
    property int customWidth: 0
    property int customHeight: 0
    // Determine content dimensions dynamically, falling back to implicit dimensions
    property real contentWidth: root.customWidth > 0 ? root.customWidth : (loader.item ? loader.item.implicitWidth : 0)
    property real contentHeight: root.customHeight > 0 ? root.customHeight : (loader.item ? loader.item.implicitHeight : 0)
    // Add safe margins to avoid content overflowing into the rounded corners
    property real safeMarginX: (isTop || isBottom) ? root.cornerRadius * 2 + root.contentPadding * 2 : root.cornerRadius + root.contentPadding * 2
    property real safeMarginY: (isLeft || isRight) ? root.cornerRadius * 2 + root.contentPadding * 2 : root.contentPadding * 2
    property int animationDuration: HyprlandService.enableAnimations ? Constants.animSlow : 0
    readonly property int closeDuration: HyprlandService.enableAnimations ? Constants.animNormal : 0
    readonly property int fadeDuration: HyprlandService.enableAnimations ? Constants.animNormal : 0
    property real openProgress: root.isOpen ? 1 : 0
    property real bounceProgress: root.isOpen ? 1 : 0
    property real targetWidth: contentWidth > 0 ? contentWidth + safeMarginX : 0
    property real targetHeight: (isLeft || isRight) ? root.height : (contentHeight > 0 ? contentHeight + safeMarginY : 0)
    property real smoothWidth: targetWidth
    property real smoothHeight: targetHeight

    signal fullyClosed()

    function close() {
        AppState.closePopup(popupId);
    }

    implicitWidth: targetWidth
    implicitHeight: (isLeft || isRight) ? 0 : targetHeight
    visible: _visible
    onIsOpenChanged: {
        if (isOpen) {
            closeDelayTimer.stop();
            _visible = true;
            if (loader.item) {
                // Call specific reset methods if they exist
                if (typeof loader.item.resetLauncher === "function")
                    loader.item.resetLauncher();

                if (typeof loader.item.resetClipboard === "function")
                    loader.item.resetClipboard();

                if (typeof loader.item.resetWallpaperSelector === "function")
                    loader.item.resetWallpaperSelector();

                if (typeof loader.item.resetPowerMenu === "function")
                    loader.item.resetPowerMenu();

                if (typeof loader.item.resetScreenCapture === "function")
                    loader.item.resetScreenCapture();

                // Force focus on the specified initial focus item
                if (loader.item.initialFocusItem)
                    loader.item.initialFocusItem.forceActiveFocus();
                else if (typeof loader.item.forceActiveFocus === "function")
                    loader.item.forceActiveFocus();
            }
        } else {
            if (!HyprlandService.enableAnimations) {
                _visible = false;
                root.fullyClosed();
            } else {
                closeDelayTimer.start();
            }
        }
    }
    states: [
        State {
            name: "open"
            when: root.isOpen

            PropertyChanges {
                target: root
                openProgress: 1
                bounceProgress: 1
            }

        },
        State {
            name: "closed"
            when: !root.isOpen

            PropertyChanges {
                target: root
                openProgress: 0
                bounceProgress: 0
            }

        }
    ]

    Timer {
        id: closeDelayTimer

        interval: root.closeDuration + 50
        repeat: false
        onTriggered: {
            if (!root.isOpen) {
                root._visible = false;
                root.fullyClosed();
            }
        }
    }

    Item {
        id: contentContainer

        readonly property real currentWidth: (root.isLeft || root.isRight) ? Math.max(smoothWidth * bounceProgress, 0.01) : smoothWidth
        readonly property real currentHeight: (root.isTop || root.isBottom) ? Math.max(smoothHeight * bounceProgress, 0.01) : smoothHeight

        clip: true
        width: Math.round(currentWidth)
        height: Math.round(currentHeight)
        Keys.forwardTo: (loader.item && loader.item.initialFocusItem) ? [loader.item.initialFocusItem] : []
        Keys.enabled: root.isOpen
        Keys.onEscapePressed: {
            AppState.activePopup = "";
        }
        x: {
            if (root.isRight)
                return Math.round(root.width - currentWidth);

            if (root.isLeft)
                return 0;

            return Math.round((root.width - currentWidth) / 2);
        }
        y: {
            if (root.isTop)
                return 0;

            if (root.isBottom)
                return Math.round(smoothHeight - currentHeight);

            return Math.round((root.height - currentHeight) / 2);
        }

        FramedShape {
            id: bg

            anchors.fill: parent
            color: root.backgroundColor
            cornerRadius: root.cornerRadius
            edge: root.edge
            isFramed: true
            enableShadow: false
        }

        Loader {
            id: loader

            // Mock widget object for contents that expect one
            property var widget

            sourceComponent: root.sourceComponent
            anchors.horizontalCenter: (root.isTop && root.popupId === "music") ? undefined : parent.horizontalCenter
            anchors.horizontalCenterOffset: (root.isTop && root.popupId === "music") ? 0 : (root.isRight ? (root.cornerRadius / 2) : (root.isLeft ? -(root.cornerRadius / 2) : 0))
            anchors.left: (root.isTop && root.popupId === "music") ? parent.left : undefined
            anchors.leftMargin: (root.isTop && root.popupId === "music") ? Math.round(root.safeMarginX / 2) : 0
            // Anchor to the expanding container's edge so it stays pinned and is revealed seamlessly
            anchors.bottom: root.isBottom ? parent.bottom : undefined
            anchors.bottomMargin: root.isBottom ? Math.round(root.safeMarginY / 2) : 0
            anchors.top: root.isTop ? parent.top : undefined
            anchors.topMargin: root.isTop ? Math.round(root.safeMarginY / 2) : 0
            anchors.verticalCenter: (!root.isBottom && !root.isTop) ? parent.verticalCenter : undefined
            width: root.contentWidth
            height: (root.isLeft || root.isRight) ? (parent.height - root.contentPadding * 2) : root.contentHeight
            opacity: root.openProgress
            onLoaded: {
                if (item && ("widget" in item || item.hasOwnProperty("widget")))
                    item.widget = widget;

                // Force explicit size on loaded item if custom sizes were provided
                if (item && item.hasOwnProperty("width") && root.customWidth > 0)
                    item.width = root.customWidth;

                if (item && item.hasOwnProperty("height")) {
                    if (root.customHeight > 0)
                        item.height = root.customHeight;
                    else if (root.isLeft || root.isRight)
                        item.height = Qt.binding(() => {
                        return loader.height;
                    });
                }
            }

            widget: QtObject {
                property bool isOpen: root.isOpen
                property int cornerRadius: root.cornerRadius
                property real openProgress: root.openProgress
                property real bounceProgress: root.bounceProgress
                property int preferredWidth: root.contentWidth
                property int preferredHeight: root.contentHeight

                function close() {
                    AppState.activePopup = "";
                }

                onIsOpenChanged: {
                    if (!isOpen && root.isOpen)
                        AppState.activePopup = "";

                }
            }

        }

    }

    Behavior on openProgress {
        enabled: HyprlandService.enableAnimations

        NumberAnimation {
            id: openProgressAnim

            duration: root.isOpen ? root.fadeDuration : root.closeDuration
            easing.type: root.isOpen ? Easing.OutCubic : Easing.InCubic
            onRunningChanged: {
                if (!running && !root.isOpen) {
                    root._visible = false;
                    root.fullyClosed();
                }
            }
        }

    }

    Behavior on bounceProgress {
        enabled: HyprlandService.enableAnimations

        NumberAnimation {
            duration: root.isOpen ? root.animationDuration : root.closeDuration
            easing.type: root.isOpen ? Easing.OutCubic : Easing.InCubic
        }

    }

    Behavior on smoothHeight {
        enabled: HyprlandService.enableAnimations && root.isOpen && (root.isTop || root.isBottom)

        NumberAnimation {
            duration: Constants.animNormal
            easing.type: Easing.OutCubic
        }

    }

    Behavior on smoothWidth {
        enabled: HyprlandService.enableAnimations && root.isOpen

        NumberAnimation {
            duration: Constants.animNormal
            easing.type: Easing.OutCubic
        }

    }

}
