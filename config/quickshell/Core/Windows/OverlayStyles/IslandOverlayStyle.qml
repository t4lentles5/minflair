import QtQuick
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Bar.Styles.Island as IslandStyle
import qs.Modules.Notifications as NotificationsModule

Item {
    id: root

    property var widget
    readonly property bool isOpen: widget ? widget.isOpen : false
    readonly property real preferredWidth: widget ? widget.smoothPreferredWidth : 0
    readonly property real preferredHeight: widget ? widget.smoothPreferredHeight : 0
    readonly property real windowRadius: widget ? widget.smoothWindowRadius : 0
    readonly property real contentPadding: widget ? widget.smoothContentPadding : 0
    readonly property var notificationService: widget ? widget.notificationService : null
    readonly property bool _windowVisible: widget ? widget._windowVisible : false
    readonly property bool forceVisible: widget ? widget.forceVisible : false
    property alias contentSlot: contentLayoutContainer
    property alias container: mainContainer
    property bool isHandover: false
    property bool isClosing: false
    readonly property real bounceProgress: widget ? widget.bounceProgress : 0

    anchors.fill: parent
    onIsOpenChanged: {
        if (isOpen) {
            handoverTimer.stop();
            isHandover = false;
            AppState.isIslandOpen = true;
            let nw = (AppState.hasActiveNotification && AppState.activeNotificationWidth > 0) ? AppState.activeNotificationWidth : 0;
            let nh = (AppState.hasActiveNotification && AppState.activeNotificationHeight > 0) ? AppState.activeNotificationHeight : 0;
            mainContainer.fromWidth = nw > 0 ? nw : ((AppState.barIslandWidth > 0) ? AppState.barIslandWidth : ((AppState.islandWidth > 0) ? AppState.islandWidth : mainContainer.fromWidth));
            mainContainer.fromHeight = nh > 0 ? nh : ((AppState.barIslandHeight > 0) ? AppState.barIslandHeight : ((AppState.islandHeight > 0) ? AppState.islandHeight : mainContainer.fromHeight));
            mainContainer.fromRadius = nh > 0 ? Constants.sizeSm : mainContainer.fromHeight / 2;
        } else {
            let nw = (AppState.hasActiveNotification && AppState.activeNotificationWidth > 0) ? AppState.activeNotificationWidth : 0;
            let nh = (AppState.hasActiveNotification && AppState.activeNotificationHeight > 0) ? AppState.activeNotificationHeight : 0;
            mainContainer.fromWidth = nw > 0 ? nw : ((AppState.barIslandWidth > 0) ? AppState.barIslandWidth : ((AppState.islandWidth > 0) ? AppState.islandWidth : mainContainer.fromWidth));
            mainContainer.fromHeight = nh > 0 ? nh : ((AppState.barIslandHeight > 0) ? AppState.barIslandHeight : ((AppState.islandHeight > 0) ? AppState.islandHeight : mainContainer.fromHeight));
            mainContainer.fromRadius = nh > 0 ? Constants.sizeSm : mainContainer.fromHeight / 2;
        }
    }

    Connections {
        function onFullyClosed() {
            if (SettingsService.barIslandMode && !widget.positionAtBottom) {
                isHandover = true;
                AppState.isIslandOpen = false;
                if (AppState.activePopup !== "")
                    AppState.activePopup = "";

                handoverTimer.restart();
            }
        }

        target: widget
    }

    Timer {
        id: handoverTimer

        interval: 60
        repeat: false
        onTriggered: {
            isHandover = false;
        }
    }

    Item {
        id: mainContainer

        readonly property real notifW: (AppState.hasActiveNotification && AppState.activeNotificationWidth > 0) ? AppState.activeNotificationWidth : 0
        readonly property real notifH: (AppState.hasActiveNotification && AppState.activeNotificationHeight > 0) ? AppState.activeNotificationHeight : 0
        property real fromWidth: notifW > 0 ? notifW : ((AppState.barIslandWidth > 0) ? AppState.barIslandWidth : ((AppState.islandWidth > 0) ? AppState.islandWidth : 180))
        property real fromHeight: notifH > 0 ? notifH : ((AppState.barIslandHeight > 0) ? AppState.barIslandHeight : ((AppState.islandHeight > 0) ? AppState.islandHeight : 36))
        property real fromRadius: notifH > 0 ? Constants.sizeSm : fromHeight / 2
        readonly property real openY: 8
        readonly property real currentWidth: Math.round(fromWidth + (preferredWidth - fromWidth) * bounceProgress)
        readonly property real currentHeight: Math.round(fromHeight + (preferredHeight - fromHeight) * bounceProgress)
        readonly property real currentRadius: Math.round(fromRadius + (windowRadius - fromRadius) * bounceProgress)

        width: currentWidth
        height: currentHeight
        anchors.horizontalCenter: parent.horizontalCenter
        transformOrigin: Item.Top
        y: openY
        opacity: (_windowVisible || isHandover || forceVisible) ? 1 : 0

        IslandStyle.IslandBackground {
            anchors.fill: parent
            radius: mainContainer.currentRadius
            enableShadow: SettingsService.barIslandMode && !isHandover
        }

        Item {
            id: notifSlotHolder

            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: (AppState.hasActiveNotification && AppState.activeNotificationWidth > 0) ? AppState.activeNotificationWidth : parent.width
            height: (AppState.hasActiveNotification && AppState.activeNotificationHeight > 0) ? AppState.activeNotificationHeight : 76
            clip: true
            visible: AppState.hasActiveNotification && opacity > 0.001
            opacity: (AppState.hasActiveNotification && !isOpen) ? (isHandover ? 1 : Math.min(1, Math.max(0, (1 - bounceProgress) / 0.7))) : 0
            transformOrigin: Item.Top

            NotificationsModule.NotificationDelegateContent {
                anchors.fill: parent
                notifData: (notificationService && notificationService.activeList && notificationService.activeList.count > 0) ? notificationService.activeList.get(0).notifData : null
                isFramed: false
            }

        }

        Item {
            id: barSlotHolder

            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: mainContainer.fromWidth
            height: mainContainer.fromHeight
            clip: true
            visible: !AppState.hasActiveNotification && opacity > 0.001
            opacity: AppState.hasActiveNotification ? 0 : (isHandover ? 1 : (!isOpen ? Math.min(1, Math.max(0, (1 - bounceProgress) / 0.7)) : 0))
            transformOrigin: Item.Top

            QtObject {
                id: dummyIslandBar

                property string activeBarStyle: "island"
                property bool isExpanded: false
            }

            IslandStyle.IslandContent {
                anchors.centerIn: parent
                mainBar: dummyIslandBar
                notificationService: root.notificationService
                animateTransitions: false
            }

        }

        // Prevent clicks on the container from reaching the dismiss area
        MouseArea {
            anchors.fill: parent
        }

        Item {
            id: contentLayoutContainer

            anchors.fill: parent
            anchors.margins: contentPadding
            clip: true
            transformOrigin: Item.Top
            opacity: !isOpen ? Math.min(1, Math.max(0, (bounceProgress - 0.4) / 0.6)) : Math.min(1, Math.max(0, (bounceProgress - 0.2) / 0.8))
            scale: !isOpen ? (0.94 + 0.06 * Math.min(1, Math.max(0, (bounceProgress - 0.3) / 0.7))) : (0.94 + 0.06 * Math.min(1, Math.max(0, (bounceProgress - 0.15) / 0.85)))
        }

    }

}
