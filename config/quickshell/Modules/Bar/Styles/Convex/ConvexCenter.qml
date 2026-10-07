import QtQuick
import Quickshell
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Bar
import qs.Modules.Bar.Components

Item {
    id: root

    property var notificationService: null
    property QtObject mainBar: null
    property real extraPadding: Constants.size3Xl
    property bool enableShadow: true
    // Flare & padding specifications matching Convex notch
    readonly property int flareW: Constants.sizeLg + 2
    readonly property int flareH: Constants.sizeLg
    readonly property int contentPadding: Constants.sizeLg
    readonly property int totalHorizPadding: (flareW + contentPadding) * 2
    readonly property int totalVertPadding: contentPadding * 2
    // State & mode flags
    readonly property bool hasActiveNotifications: notifLayer.hasActiveNotifications
    property real notifProgress: (hasActiveNotifications && !notifLayer.isRemovingNotif) ? 1 : 0
    readonly property bool isCenterExpanded: SettingsService.barConvexMode && AppState.isWidgetOpen("music")
    readonly property string activeContentType: AppState.isWidgetOpen("music") ? "music" : ""
    property bool isOpen: false
    property bool isClosing: false
    property real openProgress: 0
    readonly property bool isOverlayActive: isOpen || (openProgress > 0.001) || isClosing
    readonly property bool isOccupied: isOverlayActive || hasActiveNotifications
    // Geometry calculations
    readonly property real idleW: {
        let contentW = centerSlot.implicitWidth > 0 ? centerSlot.implicitWidth : centerSlot.targetWidth;
        let w = Math.round(contentW + flareW * 2 + root.extraPadding);
        return (w % 2 === 0) ? w : (w + 1);
    }
    readonly property real idleH: BarStyleConfig.barHeight("convex")
    readonly property real notifW: notifLayer.notifW
    readonly property real notifH: notifLayer.notifH
    readonly property real expandedW: (centerPanel.item && centerPanel.item.implicitWidth > 0 ? centerPanel.item.implicitWidth : 240) + totalHorizPadding
    readonly property real expandedH: (centerPanel.item && centerPanel.item.implicitHeight > 0 ? centerPanel.item.implicitHeight : 380) + totalVertPadding
    property real smoothIdleW: idleW
    property real smoothNotifW: notifW
    property real smoothNotifH: notifH
    property real smoothExpandedW: expandedW
    property real smoothExpandedH: expandedH
    readonly property real baseW: smoothIdleW + (smoothNotifW - smoothIdleW) * notifProgress
    readonly property real baseH: idleH + (smoothNotifH - idleH) * notifProgress
    readonly property real currentWidth: Math.round(baseW + (smoothExpandedW - baseW) * openProgress)
    readonly property real currentHeight: Math.round(baseH + (smoothExpandedH - baseH) * openProgress)
    readonly property real currentRadius: Math.round(Constants.sizeLg + (Constants.size3Xl - Constants.sizeLg) * openProgress)

    function syncDimensions() {
        if (width > 0)
            AppState.barConvexWidth = width;

        if (height > 0)
            AppState.barConvexHeight = height;

        if (SettingsService.barConvexMode) {
            let active = hasActiveNotifications && !notifLayer.isRemovingNotif;
            AppState.hasActiveNotification = active;
            AppState.activeNotificationWidth = active ? notifW : 0;
            AppState.activeNotificationHeight = active ? notifH : 0;
        }
    }

    // Music Open / Close handlers
    function openCenter() {
        if (isOpen)
            return ;

        isOpen = true;
        isClosing = false;
        AppState.isConvexOpen = true;
        openProgress = 1;
    }

    function close() {
        closeCenter();
    }

    function closeCenter() {
        if (isClosing)
            return ;

        isClosing = true;
        isOpen = false;
        openProgress = 0;
        if (!HyprlandService.enableAnimations)
            finishClosingCenter();

    }

    function finishClosingCenter() {
        if (isClosing) {
            isClosing = false;
            AppState.isConvexOpen = false;
            if (AppState.isWidgetOpen("music"))
                AppState.closeWidget("music");

        }
    }

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    implicitWidth: currentWidth
    width: currentWidth
    height: currentHeight
    onCurrentWidthChanged: syncDimensions()
    onCurrentHeightChanged: syncDimensions()
    Component.onCompleted: syncDimensions()
    onIsCenterExpandedChanged: {
        if (isCenterExpanded)
            root.openCenter();
        else if (root.isOpen)
            root.closeCenter();
    }

    // LAYER 1: BAR CONTENT (Clock / Idle Widget)
    Item {
        id: barContentContainer

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.round(root.smoothIdleW)
        height: root.idleH
        opacity: {
            let p = Math.max(root.openProgress, root.notifProgress);
            return Math.min(1, Math.max(0, 1 - p / 0.15));
        }
        scale: {
            let p = Math.max(root.openProgress, root.notifProgress);
            return 1 - 0.04 * Math.min(1, p / 0.15);
        }
        visible: opacity > 0.001
        clip: true

        BarCenterSection {
            id: centerSlot

            anchors.centerIn: parent
            mainBar: root.mainBar ? root.mainBar : root
        }

    }

    // LAYER 2: NOTIFICATION CONTENT
    ConvexNotifLayer {
        id: notifLayer

        notificationService: root.notificationService
        flareW: root.flareW
        isExpandedOpen: root.isOpen
        openProgress: root.openProgress
        notifProgress: root.notifProgress
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.max(0, root.smoothNotifW - (root.flareW * 2) - 8)
        height: Math.max(0, root.smoothNotifH - 14)
    }

    // LAYER 3: MUSIC WIDGET (MiniMusicWidget)
    ConvexCenterPanel {
        id: centerPanel

        centerWidget: root
        flareW: root.flareW
        contentPadding: root.contentPadding
        isClosing: root.isClosing
        openProgress: root.openProgress
        isOpen: root.isOpen
        activeContentType: root.activeContentType
    }

    // ANIMATIONS & BEHAVIORS
    Behavior on openProgress {
        enabled: HyprlandService.enableAnimations

        NumberAnimation {
            duration: root.isClosing ? Constants.animNormal : Constants.animExpressive
            easing.type: root.isClosing ? Easing.OutCubic : Easing.OutQuint
            onRunningChanged: {
                if (!running && root.isClosing)
                    root.finishClosingCenter();

            }
        }

    }

    Behavior on notifProgress {
        enabled: HyprlandService.enableAnimations

        NumberAnimation {
            duration: notifLayer.isRemovingNotif ? Constants.animFast : Constants.animExpressive
            easing.type: notifLayer.isRemovingNotif ? Easing.OutCubic : Easing.OutQuint
            onRunningChanged: {
                if (!running && notifLayer.isRemovingNotif) {
                    notifLayer.isRemovingNotif = false;
                    notifLayer.dismissActiveNotifications();
                }
            }
        }

    }

    Behavior on smoothExpandedW {
        enabled: HyprlandService.enableAnimations && root.openProgress >= 0.85

        NumberAnimation {
            duration: Constants.animSlow
            easing.type: Easing.OutQuint
        }

    }

    Behavior on smoothExpandedH {
        enabled: HyprlandService.enableAnimations && root.openProgress >= 0.85

        NumberAnimation {
            duration: Constants.animSlow
            easing.type: Easing.OutQuint
        }

    }

    Behavior on smoothNotifW {
        enabled: HyprlandService.enableAnimations && root.notifProgress >= 0.85

        NumberAnimation {
            duration: Constants.animSlow
            easing.type: Easing.OutQuint
        }

    }

    Behavior on smoothNotifH {
        enabled: HyprlandService.enableAnimations && root.notifProgress >= 0.85

        NumberAnimation {
            duration: Constants.animSlow
            easing.type: Easing.OutQuint
        }

    }

    Behavior on smoothIdleW {
        enabled: HyprlandService.enableAnimations

        NumberAnimation {
            duration: Constants.animNormal
            easing.type: Easing.OutCubic
        }

    }

}
