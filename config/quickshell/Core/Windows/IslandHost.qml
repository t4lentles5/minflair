import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Core.Windows.Components
import qs.Modules.Bar.Styles.Island as IslandStyle
import qs.Modules.Notifications as NotificationsModule

Item {
    id: root

    property var notificationService: null

    visible: crossfadeHost.isOverlayActive

    PopupCrossfadeHost {
        id: crossfadeHost

        anchors.fill: parent
        notificationService: root.notificationService
        barMode: "island"
        visualContainer: islandRect
        contentHorizontalPadding: Constants.sizeLg
        contentVerticalPadding: Constants.sizeLg
        defaultWidth: (AppState.hasActiveNotification && AppState.activeNotificationWidth > 0) ? AppState.activeNotificationWidth : ((AppState.barIslandWidth > 0) ? AppState.barIslandWidth : ((AppState.islandWidth > 0) ? AppState.islandWidth : 180))
        defaultHeight: (AppState.hasActiveNotification && AppState.activeNotificationHeight > 0) ? AppState.activeNotificationHeight : ((AppState.barIslandHeight > 0) ? AppState.barIslandHeight : ((AppState.islandHeight > 0) ? AppState.islandHeight : 36))
    }

    IslandStyle.IslandBackground {
        id: islandRect

        property real fromWidth: crossfadeHost.defaultWidth
        property real fromHeight: crossfadeHost.defaultHeight
        property real fromRadius: (AppState.hasActiveNotification && AppState.activeNotificationHeight > 0) ? Constants.sizeSm : fromHeight / 2
        readonly property real targetW: crossfadeHost.getTargetWidth(crossfadeHost.effectivePopup, crossfadeHost.activeItem)
        readonly property real targetH: crossfadeHost.getTargetHeight(crossfadeHost.effectivePopup, crossfadeHost.activeItem)
        readonly property real targetR: (crossfadeHost.effectivePopup === "") ? ((AppState.barIslandRadius > 0) ? AppState.barIslandRadius : ((AppState.islandRadius > 0) ? AppState.islandRadius : ((AppState.islandHeight > 0) ? (AppState.islandHeight / 2) : 18))) : Constants.size3Xl
        property real smoothTargetW: targetW
        property real smoothTargetH: targetH
        property real smoothTargetR: targetR
        property real openProgress: 0
        readonly property real currentWidth: Math.round(fromWidth + (smoothTargetW - fromWidth) * openProgress)
        readonly property real currentHeight: Math.round(fromHeight + (smoothTargetH - fromHeight) * openProgress)
        readonly property real currentRadius: Math.round(fromRadius + (smoothTargetR - fromRadius) * openProgress)

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 8
        width: currentWidth
        height: currentHeight
        radius: currentRadius
        visible: crossfadeHost.isOverlayActive
        enableShadow: !crossfadeHost.isHandover
        Keys.forwardTo: {
            if (!crossfadeHost.needsFocus || !crossfadeHost.activeItem || !crossfadeHost.activeItem.initialFocusItem)
                return [];

            let it = crossfadeHost.activeItem.initialFocusItem;
            if (it.textField)
                return [it.textField, it];

            return [it];
        }
        Keys.enabled: crossfadeHost.isOpen && crossfadeHost.needsFocus
        Keys.onEscapePressed: crossfadeHost.close()

        MouseArea {
            anchors.fill: parent
        }

        Item {
            id: notifSlotHolder

            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: (AppState.hasActiveNotification && AppState.activeNotificationWidth > 0) ? AppState.activeNotificationWidth : parent.width
            height: (AppState.hasActiveNotification && AppState.activeNotificationHeight > 0) ? AppState.activeNotificationHeight : 76
            clip: true
            visible: AppState.hasActiveNotification && opacity > 0.001
            opacity: (AppState.hasActiveNotification && !crossfadeHost.isOpen) ? (crossfadeHost.isHandover ? 1 : Math.min(1, Math.max(0, (1 - islandRect.openProgress) / 0.7))) : 0
            transformOrigin: Item.Top

            NotificationsModule.NotificationDelegateContent {
                anchors.fill: parent
                notifData: (root.notificationService && root.notificationService.activeList && root.notificationService.activeList.count > 0) ? root.notificationService.activeList.get(0).notifData : null
                isFramed: false
            }

        }

        Item {
            id: barSlotHolder

            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: islandRect.fromWidth
            height: islandRect.fromHeight
            clip: true
            visible: !AppState.hasActiveNotification && opacity > 0.001
            opacity: AppState.hasActiveNotification ? 0 : (crossfadeHost.isHandover ? 1 : (crossfadeHost.isRemoving ? Math.min(1, Math.max(0, (1 - islandRect.openProgress) / 0.7)) : 0))
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
            }

        }

        Item {
            id: contentContainer

            anchors.fill: parent
            anchors.margins: crossfadeHost.effectivePopup !== "" ? Constants.sizeLg : 0
            clip: true
            opacity: crossfadeHost.isRemoving ? Math.min(1, Math.max(0, (islandRect.openProgress - 0.4) / 0.6)) : Math.min(1, Math.max(0, (islandRect.openProgress - 0.2) / 0.8))
            scale: crossfadeHost.isRemoving ? (0.94 + 0.06 * Math.min(1, Math.max(0, (islandRect.openProgress - 0.3) / 0.7))) : (0.94 + 0.06 * Math.min(1, Math.max(0, (islandRect.openProgress - 0.15) / 0.85)))
            transformOrigin: Item.Top

            Loader {
                id: displayLoader

                width: crossfadeHost.getContentWidth(crossfadeHost.activePopupName, item) > 0 ? crossfadeHost.getContentWidth(crossfadeHost.activePopupName, item) : parent.width
                height: crossfadeHost.getContentHeight(crossfadeHost.activePopupName, item) > 0 ? crossfadeHost.getContentHeight(crossfadeHost.activePopupName, item) : parent.height
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                sourceComponent: crossfadeHost.contentLoader.sourceComponent
                onStatusChanged: {
                    if (status === Loader.Ready && item) {
                        if (item.widget !== undefined)
                            item.widget = root;

                        // Let crossfadeHost know about the visual item
                        crossfadeHost.contentLoader.item = item;
                    }
                }
            }

        }

        Behavior on smoothTargetW {
            enabled: HyprlandService.enableAnimations && islandRect.openProgress >= 0.85

            NumberAnimation {
                duration: Constants.animSlow
                easing.type: Easing.OutQuint
            }

        }

        Behavior on smoothTargetH {
            enabled: HyprlandService.enableAnimations && islandRect.openProgress >= 0.85

            NumberAnimation {
                duration: Constants.animSlow
                easing.type: Easing.OutQuint
            }

        }

        Behavior on smoothTargetR {
            enabled: HyprlandService.enableAnimations && islandRect.openProgress >= 0.85

            NumberAnimation {
                duration: Constants.animSlow
                easing.type: Easing.OutQuint
            }

        }

        Behavior on openProgress {
            enabled: HyprlandService.enableAnimations

            NumberAnimation {
                duration: crossfadeHost.isRemoving ? Constants.animNormal : Constants.animExpressive
                easing.type: crossfadeHost.isRemoving ? Easing.OutCubic : Easing.OutQuint
                onRunningChanged: {
                    if (!running && crossfadeHost.isRemoving)
                        crossfadeHost.finishClosing();

                }
            }

        }

    }

}
