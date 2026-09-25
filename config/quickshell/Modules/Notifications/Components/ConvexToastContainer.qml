import QtQuick
import Quickshell
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Bar.Components as BarComponents
import qs.Modules.Notifications

Item {
    id: toastContainer

    property var overlayRoot
    property real fromWidth: (AppState.barConvexWidth > 0) ? AppState.barConvexWidth : 220
    property real fromHeight: (AppState.barConvexHeight > 0) ? AppState.barConvexHeight : 36
    property bool isRemoving: false
    property bool isHandover: false
    property bool isHovered: mainMouseArea.containsMouse
    property real dragOffset: 0
    property bool expanded: false
    readonly property var activeNotifData: overlayRoot ? ((overlayRoot.activeSlot === "A") ? overlayRoot.notifDataA : overlayRoot.notifDataB) : null
    readonly property var activeContentItem: (overlayRoot && overlayRoot.activeSlot === "A") ? contentA : contentB
    readonly property real targetToastWidth: 380 + notchBg.flareWidth * 2
    readonly property real targetToastHeight: {
        let h = activeContentItem ? activeContentItem.implicitHeight : 0;
        return Math.max(h + Constants.sizeSm * 2 + 14, 76);
    }
    property real closeDuration: Constants.animNormal
    property real openProgress: 0
    readonly property real currentWidth: fromWidth + (targetToastWidth - fromWidth) * openProgress
    readonly property real currentHeight: fromHeight + (targetToastHeight - fromHeight) * openProgress

    function closeNotification() {
        if (isRemoving)
            return ;

        isRemoving = true;
        fromWidth = (AppState.barConvexWidth > 0) ? AppState.barConvexWidth : 220;
        fromHeight = (AppState.barConvexHeight > 0) ? AppState.barConvexHeight : 36;
        expanded = false;
        openProgress = 0;
        closeAnimTimer.start();
    }

    function closeImmediately() {
        if (overlayRoot && overlayRoot.handoverTimer)
            overlayRoot.handoverTimer.stop();

        closeAnimTimer.stop();
        isHandover = false;
        isRemoving = true;
        openProgress = 0;
        if (overlayRoot && overlayRoot.notchDisplayTimer)
            overlayRoot.notchDisplayTimer.stop();

        dragOffset = 0;
        isRemoving = false;
        if (overlayRoot)
            overlayRoot.dismissActiveNotifications();

    }

    function transitionToNewNotification(nd) {
        expanded = false;
        contentTransitionAnim.stop();
        let nextSlot = (overlayRoot.activeSlot === "A") ? "B" : "A";
        if (nextSlot === "A") {
            overlayRoot.notifDataA = nd;
            overlayRoot.activeSlot = "A";
            contentTransitionAnim.startTransition(true);
        } else {
            overlayRoot.notifDataB = nd;
            overlayRoot.activeSlot = "B";
            contentTransitionAnim.startTransition(false);
        }
        if (overlayRoot && overlayRoot.notchDisplayTimer)
            overlayRoot.notchDisplayTimer.restart();

    }

    onTargetToastWidthChanged: {
        if (SettingsService.barConvexMode && AppState.hasActiveNotification)
            AppState.activeNotificationWidth = targetToastWidth;

    }
    onTargetToastHeightChanged: {
        if (SettingsService.barConvexMode && AppState.hasActiveNotification)
            AppState.activeNotificationHeight = targetToastHeight;

    }
    onIsRemovingChanged: {
        if (overlayRoot)
            overlayRoot.syncNotifState();

    }
    onExpandedChanged: {
        let d = activeNotifData || (overlayRoot ? overlayRoot.currentNotifData : null);
        if (d) {
            if (expanded)
                d.lock("expanded");
            else
                d.unlock("expanded");
        }
    }
    width: currentWidth
    height: currentHeight
    clip: false
    opacity: ((overlayRoot && overlayRoot.isOverlayActive) ? 1 : 0) * Math.max(0, 1 - Math.abs(dragOffset) / (width / 2))
    visible: overlayRoot && overlayRoot.isOverlayActive

    Connections {
        function onPopupChanged() {
            let d = toastContainer.activeNotifData || (overlayRoot ? overlayRoot.currentNotifData : null);
            if (d && !d.popup && !toastContainer.isRemoving)
                toastContainer.closeNotification();

        }

        target: toastContainer.activeNotifData ? toastContainer.activeNotifData : (overlayRoot ? overlayRoot.currentNotifData : null)
    }

    Connections {
        function onActivePopupChanged() {
            handleStateChange();
        }

        function onIsConvexOpenChanged() {
            handleStateChange();
        }

        function handleStateChange() {
            if (!overlayRoot)
                return ;

            if (overlayRoot.isHostPopupActive) {
                overlayRoot.wasPausedByHostPopup = true;
                overlayRoot.syncNotifState();
                if (overlayRoot.notchDisplayTimer)
                    overlayRoot.notchDisplayTimer.stop();

                toastContainer.dragOffset = 0;
            } else if (!overlayRoot.isHostPopupActive) {
                if (overlayRoot.hasActiveNotifications) {
                    toastContainer.isRemoving = false;
                    toastContainer.openProgress = 1;
                    overlayRoot.syncNotifState();
                    if (overlayRoot.wasPausedByHostPopup) {
                        overlayRoot.wasPausedByHostPopup = false;
                        if (!toastContainer.isHovered && overlayRoot.notchDisplayTimer && overlayRoot.notchDisplayTimer.interval > 0)
                            overlayRoot.notchDisplayTimer.restart();

                    }
                } else {
                    overlayRoot.wasPausedByHostPopup = false;
                }
            }
        }

        target: AppState
    }

    Timer {
        id: closeAnimTimer

        interval: toastContainer.closeDuration + 100
        repeat: false
        onTriggered: {
            if (overlayRoot)
                overlayRoot.finishClosing();

        }
    }

    NotchShape {
        id: notchBg

        anchors.fill: parent
        color: Theme.bg
        flareWidth: 18
        flareHeight: 16
        topBezel: 8
        bottomRadius: Constants.sizeLg
        enableShadow: SettingsService.barConvexMode && !toastContainer.isHandover
    }

    Item {
        id: barSlotHolder

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: (AppState.barConvexWidth > 0) ? AppState.barConvexWidth : 220
        height: (AppState.barConvexHeight > 0) ? AppState.barConvexHeight : 36
        clip: true
        visible: opacity > 0.001
        opacity: toastContainer.isHandover ? 1 : (toastContainer.isRemoving ? Math.min(1, Math.max(0, (1 - toastContainer.openProgress) / 0.7)) : 0)
        transformOrigin: Item.Top

        BarComponents.BarCenterSection {
            anchors.centerIn: parent
            mainBar: overlayRoot
        }

    }

    MouseArea {
        id: mainMouseArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onEntered: {
            let d = toastContainer.activeNotifData || (overlayRoot ? overlayRoot.currentNotifData : null);
            if (d)
                d.lock(toastContainer);

        }
        onExited: {
            let d = toastContainer.activeNotifData || (overlayRoot ? overlayRoot.currentNotifData : null);
            if (d)
                d.unlock(toastContainer);

        }
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton)
                toastContainer.closeImmediately();
            else
                toastContainer.closeNotification();
        }
    }

    DragHandler {
        id: dragHandler

        target: null
        xAxis.enabled: true
        yAxis.enabled: true
        onTranslationChanged: {
            if (Math.abs(translation.x) > Math.abs(translation.y))
                toastContainer.dragOffset = translation.x;
            else if (translation.y < -15)
                toastContainer.closeNotification();
        }
        onActiveChanged: {
            if (!active) {
                if (Math.abs(toastContainer.dragOffset) > toastContainer.width / 4)
                    toastContainer.closeNotification();
                else
                    snapBackAnim.restart();
            }
        }
    }

    NumberAnimation {
        id: snapBackAnim

        target: toastContainer
        property: "dragOffset"
        to: 0
        duration: Constants.animFast
        easing.type: Easing.OutBack
    }

    ParallelAnimation {
        id: contentTransitionAnim

        property bool targetIsA: true

        function startTransition(toA) {
            targetIsA = toA;
            restart();
        }

        NumberAnimation {
            target: contentTransitionAnim.targetIsA ? slotBHolder : slotAHolder
            property: "opacity"
            to: 0
            duration: Constants.animFast
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: contentTransitionAnim.targetIsA ? slotBHolder : slotAHolder
            property: "scale"
            to: 0.98
            duration: Constants.animFast
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: contentTransitionAnim.targetIsA ? slotBTranslate : slotATranslate
            property: "y"
            to: -4
            duration: Constants.animFast
            easing.type: Easing.OutCubic
        }

        SequentialAnimation {
            PauseAnimation {
                duration: 30
            }

            ParallelAnimation {
                NumberAnimation {
                    target: contentTransitionAnim.targetIsA ? slotAHolder : slotBHolder
                    property: "opacity"
                    to: 1
                    duration: Constants.animSlow
                    easing.type: Easing.OutCubic
                }

                NumberAnimation {
                    target: contentTransitionAnim.targetIsA ? slotAHolder : slotBHolder
                    property: "scale"
                    to: 1
                    duration: Constants.animSlow
                    easing.type: Easing.OutQuint
                }

                NumberAnimation {
                    target: contentTransitionAnim.targetIsA ? slotATranslate : slotBTranslate
                    property: "y"
                    to: 0
                    duration: Constants.animSlow
                    easing.type: Easing.OutQuint
                }

            }

        }

    }

    Item {
        id: contentArea

        anchors.fill: parent
        anchors.leftMargin: notchBg.flareWidth + 4
        anchors.rightMargin: notchBg.flareWidth + 4
        anchors.topMargin: 0
        anchors.bottomMargin: 14
        clip: true
        opacity: {
            let dragFactor = Math.max(0, 1 - Math.abs(toastContainer.dragOffset) / (toastContainer.width / 2));
            let progressOpacity = toastContainer.isRemoving ? Math.min(1, Math.max(0, (toastContainer.openProgress - 0.4) / 0.6)) : Math.min(1, Math.max(0, (toastContainer.openProgress - 0.2) / 0.8));
            return progressOpacity * dragFactor;
        }

        Item {
            id: slotAHolder

            anchors.fill: parent
            transformOrigin: Item.Top
            opacity: 1
            scale: 1
            visible: opacity > 0.001

            NotificationDelegateContent {
                id: contentA

                anchors.fill: parent
                notifData: overlayRoot ? overlayRoot.notifDataA : null
                expanded: toastContainer.expanded
                isFramed: false
            }

            transform: Translate {
                id: slotATranslate

                y: 0
            }

        }

        Item {
            id: slotBHolder

            anchors.fill: parent
            transformOrigin: Item.Top
            opacity: 0
            scale: 0.98
            visible: opacity > 0.001

            NotificationDelegateContent {
                id: contentB

                anchors.fill: parent
                notifData: overlayRoot ? overlayRoot.notifDataB : null
                expanded: toastContainer.expanded
                isFramed: false
            }

            transform: Translate {
                id: slotBTranslate

                y: 4
            }

        }

    }

    transform: Translate {
        x: toastContainer.dragOffset
    }

    Behavior on openProgress {
        NumberAnimation {
            duration: toastContainer.isRemoving ? toastContainer.closeDuration : Constants.animNormal
            easing.type: toastContainer.isRemoving ? Easing.OutCubic : Easing.OutQuint
            onRunningChanged: {
                if (!running && toastContainer.isRemoving && overlayRoot)
                    overlayRoot.finishClosing();

            }
        }

    }

}
