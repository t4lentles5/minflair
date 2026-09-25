import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Bar.Components as BarComponents
import qs.Modules.Notifications.Components

Item {
    id: root

    required property var notificationService
    readonly property var currentItem: (notificationService && notificationService.activeList && notificationService.activeList.count > 0) ? notificationService.activeList.get(0) : null
    readonly property var currentNotifData: currentItem ? currentItem.notifData : null
    readonly property string currentNotifId: currentNotifData ? (currentNotifData.notificationId || "") : ""
    readonly property bool hasActiveNotifications: currentNotifData !== null
    readonly property bool isHostPopupActive: AppState.isConvexOpen || AppState.activePopup === "music"
    readonly property bool isOverlayActive: (hasActiveNotifications || (toastContainer && toastContainer.openProgress > 0.001) || (toastContainer && toastContainer.isRemoving) || handoverTimer.running) && !isHostPopupActive
    property bool wasPausedByHostPopup: false
    property alias blockContainer: blockContainer
    property string activeSlot: "A"
    property string activeNotifId: ""
    property var notifDataA: null
    property var notifDataB: null

    function finishClosing() {
        closeAnimTimer.stop();
        if (toastContainer && toastContainer.isRemoving) {
            toastContainer.isHandover = true;
            root.dismissActiveNotifications();
            handoverTimer.restart();
        }
    }

    function syncNotifState() {
        if (!SettingsService.barConvexMode)
            return ;

        let active = root.hasActiveNotifications && (!toastContainer || !toastContainer.isRemoving);
        AppState.hasActiveNotification = active;
        if (active && toastContainer) {
            AppState.activeNotificationWidth = toastContainer.targetToastWidth;
            AppState.activeNotificationHeight = toastContainer.targetToastHeight;
        } else {
            AppState.activeNotificationWidth = 0;
            AppState.activeNotificationHeight = 0;
        }
    }

    function dismissActiveNotifications() {
        if (root.notificationService && root.notificationService.activeList) {
            while (root.notificationService.activeList.count > 0) {
                let item = root.notificationService.activeList.get(0);
                if (item && item.notifData) {
                    let id = item.notifData.notificationId;
                    if (item.notifData.closed || item.notifData.isTransient)
                        root.notificationService.dismissNotification(id);
                    else
                        root.notificationService.activeList.remove(0);
                } else if (item && item.id) {
                    root.notificationService.dismissNotification(item.id);
                } else {
                    root.notificationService.activeList.remove(0);
                }
            }
        }
        if (toastContainer)
            toastContainer.dragOffset = 0;

    }

    onHasActiveNotificationsChanged: syncNotifState()
    onCurrentNotifDataChanged: syncNotifState()
    Component.onCompleted: syncNotifState()
    Component.onDestruction: {
        if (SettingsService.barConvexMode) {
            AppState.hasActiveNotification = false;
            AppState.activeNotificationWidth = 0;
            AppState.activeNotificationHeight = 0;
        }
    }
    visible: isOverlayActive
    onCurrentNotifIdChanged: {
        if (currentNotifId !== "" && currentNotifId !== activeNotifId) {
            activeNotifId = currentNotifId;
            let nd = currentNotifData;
            if (nd) {
                handoverTimer.stop();
                if (toastContainer) {
                    toastContainer.isHandover = false;
                    toastContainer.isRemoving = false;
                    toastContainer.dragOffset = 0;
                    toastContainer.expanded = false;
                }
                if (toastContainer.openProgress < 0.85) {
                    toastContainer.fromWidth = (AppState.barConvexWidth > 0) ? AppState.barConvexWidth : 220;
                    toastContainer.fromHeight = (AppState.barConvexHeight > 0) ? AppState.barConvexHeight : 36;
                    activeSlot = "A";
                    notifDataA = nd;
                    notifDataB = null;
                } else {
                    if (activeSlot === "A") {
                        activeSlot = "B";
                        notifDataB = nd;
                        toastContainer.fromWidth = toastContainer.targetToastWidth;
                        toastContainer.fromHeight = toastContainer.targetToastHeight;
                    } else {
                        activeSlot = "A";
                        notifDataA = nd;
                        toastContainer.fromWidth = toastContainer.targetToastWidth;
                        toastContainer.fromHeight = toastContainer.targetToastHeight;
                    }
                }
                toastContainer.openProgress = 1;
            }
        } else if (currentNotifId === "") {
            activeNotifId = "";
            root.syncNotifState();
        }
    }

    Timer {
        id: handoverTimer

        interval: 60
        repeat: false
        onTriggered: {
            if (toastContainer) {
                toastContainer.isRemoving = false;
                toastContainer.isHandover = false;
            }
            root.syncNotifState();
        }
    }

    Timer {
        id: notchDisplayTimer

        interval: {
            let d = (root.activeSlot === "A" ? root.notifDataA : root.notifDataB) || root.currentNotifData;
            if (!d)
                return 5500;

            if (d.summary === "Volume" || d.summary === "Brightness" || d.summary === "Microphone")
                return 1800;

            if (d.urgency === 2)
                return -1;

            return 5500;
        }
        running: root.hasActiveNotifications && !toastContainer.isRemoving && !toastContainer.isHovered && interval > 0 && !root.isHostPopupActive
        repeat: false
        onTriggered: toastContainer.closeNotification()
    }

    Item {
        id: blockContainer

        readonly property real targetWidth: root.isOverlayActive ? toastContainer.currentWidth : 0
        readonly property real targetHeight: root.isOverlayActive ? toastContainer.currentHeight : 0

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 0
        width: targetWidth
        height: targetHeight
        visible: root.isOverlayActive

        ConvexToastContainer {
            id: toastContainer

            overlayRoot: root
        }

    }

}
