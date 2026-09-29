import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Bar
import qs.Modules.Bar.Components
import qs.Modules.Bar.Styles.Components
import qs.Modules.MusicPopup as MusicModule
import qs.Modules.Notifications as NotificationsModule

Item {
    id: root

    property var notificationService: null
    property var mainPanelWidget: null
    property QtObject mainBar: null
    property real notchTopBezel: 8
    property real extraPadding: 32
    property bool showNotchShape: false
    property bool enableShadow: true
    // Flare & padding specifications matching Convex notch
    readonly property int flareW: 18
    readonly property int flareH: 16
    readonly property int contentPadding: Constants.sizeLg
    readonly property int totalHorizPadding: (flareW + contentPadding) * 2
    readonly property int totalVertPadding: contentPadding * 2
    // Notifications logic
    readonly property var currentNotifItem: (notificationService && notificationService.activeList && notificationService.activeList.count > 0) ? notificationService.activeList.get(0) : null
    readonly property var currentNotifData: currentNotifItem ? currentNotifItem.notifData : null
    readonly property bool hasActiveNotifications: currentNotifData !== null
    property string activeSlot: "A"
    property var notifDataA: null
    property var notifDataB: null
    property bool _isPruning: false
    property bool isRemovingNotif: false
    property real dragOffset: 0
    property bool isHovered: false
    property bool expanded: false
    property real notifProgress: (hasActiveNotifications && !isRemovingNotif) ? 1 : 0
    // Music Popup logic
    readonly property bool isMusicPopup: SettingsService.barConvexMode && AppState.isPopupOpen("music")
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
    readonly property real notifW: getNotifTargetWidth(activeSlot === "A" ? notifDataA : notifDataB)
    readonly property real notifH: getNotifTargetHeight(activeSlot === "A" ? contentA : contentB)
    readonly property real musicW: (musicLoader.item && musicLoader.item.implicitWidth > 0 ? musicLoader.item.implicitWidth : 240) + totalHorizPadding
    readonly property real musicH: (musicLoader.item && musicLoader.item.implicitHeight > 0 ? musicLoader.item.implicitHeight : 380) + totalVertPadding
    property real smoothNotifW: notifW
    property real smoothNotifH: notifH
    property real smoothMusicW: musicW
    property real smoothMusicH: musicH
    readonly property real baseW: idleW + (smoothNotifW - idleW) * notifProgress
    readonly property real baseH: idleH + (smoothNotifH - idleH) * notifProgress
    readonly property real currentWidth: Math.round(baseW + (smoothMusicW - baseW) * openProgress)
    readonly property real currentHeight: Math.round(baseH + (smoothMusicH - baseH) * openProgress)
    readonly property real currentRadius: Math.round(Constants.sizeLg + (Constants.size3Xl - Constants.sizeLg) * openProgress)

    function getNotifTargetWidth(notifData) {
        return 380 + (flareW * 2);
    }

    function getNotifTargetHeight(contentItem) {
        let h = contentItem ? contentItem.implicitHeight : 0;
        return Math.max(h + Constants.sizeSm * 2 + 14, 76);
    }

    function syncDimensions() {
        if (width > 0)
            AppState.barConvexWidth = width;

        if (height > 0)
            AppState.barConvexHeight = height;

        if (SettingsService.barConvexMode) {
            let active = hasActiveNotifications && !isRemovingNotif;
            AppState.hasActiveNotification = active;
            if (active) {
                AppState.activeNotificationWidth = notifW;
                AppState.activeNotificationHeight = notifH;
            } else {
                AppState.activeNotificationWidth = 0;
                AppState.activeNotificationHeight = 0;
            }
        }
    }

    // Music Open / Close handlers
    function openMusic() {
        if (isOpen)
            return ;

        isOpen = true;
        isClosing = false;
        AppState.isConvexOpen = true;
        openProgress = 1;
    }

    function close() {
        closeMusic();
    }

    function closeMusic() {
        if (isClosing)
            return ;

        isClosing = true;
        isOpen = false;
        openProgress = 0;
        if (!HyprlandService.enableAnimations)
            finishClosingMusic();

    }

    function finishClosingMusic() {
        if (isClosing) {
            isClosing = false;
            AppState.isConvexOpen = false;
            if (AppState.isPopupOpen("music"))
                AppState.closePopup("music");

        }
    }

    // Notifications handlers
    function pruneActiveNotifications() {
        if (_isPruning || !notificationService || !notificationService.activeList)
            return ;

        _isPruning = true;
        while (notificationService.activeList.count > 1) {
            let oldItem = notificationService.activeList.get(1);
            if (oldItem && oldItem.notifData)
                oldItem.notifData.popup = false;

            notificationService.activeList.remove(1);
        }
        _isPruning = false;
    }

    function dismissActiveNotifications() {
        if (notificationService && notificationService.activeList) {
            while (notificationService.activeList.count > 0) {
                let item = notificationService.activeList.get(0);
                if (item && item.notifData) {
                    let id = item.notifData.notificationId;
                    if (item.notifData.closed || item.notifData.isTransient)
                        notificationService.dismissNotification(id);
                    else
                        notificationService.activeList.remove(0);
                } else {
                    notificationService.activeList.remove(0);
                }
            }
        }
        root.dragOffset = 0;
    }

    function closeNotification() {
        if (root.isRemovingNotif || !currentNotifData)
            return ;

        root.isRemovingNotif = true;
        notchDisplayTimer.stop();
    }

    function closeNotificationImmediately() {
        root.isRemovingNotif = true;
        notchDisplayTimer.stop();
        root.dragOffset = 0;
        root.isRemovingNotif = false;
        dismissActiveNotifications();
    }

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    implicitWidth: currentWidth
    width: currentWidth
    height: currentHeight
    onCurrentWidthChanged: syncDimensions()
    onCurrentHeightChanged: syncDimensions()
    Component.onCompleted: syncDimensions()
    onCurrentNotifDataChanged: {
        Qt.callLater(pruneActiveNotifications);
        if (currentNotifData) {
            root.isRemovingNotif = false;
            root.dragOffset = 0;
            if (!notifDataA && !notifDataB) {
                activeSlot = "A";
                notifDataA = currentNotifData;
                notifDataB = null;
                slotAHolder.opacity = 1;
                slotAHolder.scale = 1;
                slotATranslate.y = 0;
                slotBHolder.opacity = 0;
                slotBHolder.scale = 0.98;
                slotBTranslate.y = 4;
            } else {
                if (activeSlot === "A") {
                    notifDataB = currentNotifData;
                    activeSlot = "B";
                    contentTransitionAnim.startTransition(false);
                } else {
                    notifDataA = currentNotifData;
                    activeSlot = "A";
                    contentTransitionAnim.startTransition(true);
                }
            }
            notchDisplayTimer.restart();
        }
    }
    onIsMusicPopupChanged: {
        if (isMusicPopup)
            root.openMusic();
        else if (root.isOpen)
            root.closeMusic();
    }

    Connections {
        function onCountChanged() {
            Qt.callLater(pruneActiveNotifications);
        }

        target: (notificationService && notificationService.activeList) ? notificationService.activeList : null
    }

    Timer {
        id: notchDisplayTimer

        interval: {
            let d = (activeSlot === "A" ? notifDataA : notifDataB) || currentNotifData;
            if (!d)
                return 5500;

            if (d.summary === "Volume" || d.summary === "Brightness" || d.summary === "Microphone")
                return 1800;

            if (d.urgency === 2)
                return -1;

            return 5500;
        }
        running: hasActiveNotifications && !root.isRemovingNotif && !root.isHovered && interval > 0 && !root.isOpen
        repeat: false
        onTriggered: closeNotification()
    }

    // Optional NotchShape for isolated testing (normally ConvexShape provides background)
    SectionNotchShape {
        id: notchBg

        visible: root.showNotchShape
        anchors.fill: parent
        mode: "center"
        flareWidth: 18
        flareHeight: 16
        bottomRadius: root.currentRadius
        topBezel: root.notchTopBezel
        color: Theme.bg
        enableShadow: root.enableShadow
    }

    // Mouse & gesture handling
    MouseArea {
        // Handled inside music popup

        id: mainMouseArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: (root.notifProgress > 0 && root.openProgress === 0) ? Qt.PointingHandCursor : Qt.ArrowCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onEntered: {
            root.isHovered = true;
            let d = (activeSlot === "A" ? notifDataA : notifDataB) || currentNotifData;
            if (d && root.notifProgress > 0 && root.openProgress === 0)
                d.lock(root);

        }
        onExited: {
            root.isHovered = false;
            let d = (activeSlot === "A" ? notifDataA : notifDataB) || currentNotifData;
            if (d && root.notifProgress > 0 && root.openProgress === 0)
                d.unlock(root);

        }
        onClicked: (mouse) => {
            if (root.openProgress > 0) {
            } else if (root.notifProgress > 0) {
                if (mouse.button === Qt.LeftButton)
                    closeNotificationImmediately();
                else
                    closeNotification();
            }
        }
    }

    DragHandler {
        id: dragHandler

        target: null
        xAxis.enabled: root.notifProgress > 0 && root.openProgress === 0
        yAxis.enabled: root.notifProgress > 0 && root.openProgress === 0
        onTranslationChanged: {
            if (root.notifProgress === 0 || root.openProgress > 0)
                return ;

            if (Math.abs(translation.x) > Math.abs(translation.y))
                root.dragOffset = translation.x;
            else if (translation.y < -15)
                closeNotification();
        }
        onActiveChanged: {
            if (!active) {
                if (Math.abs(root.dragOffset) > root.width / 4)
                    closeNotification();
                else
                    snapBackAnim.restart();
            }
        }
    }

    NumberAnimation {
        id: snapBackAnim

        target: root
        property: "dragOffset"
        to: 0
        duration: Constants.animFast
        easing.type: Easing.OutBack
    }

    // ==========================================
    // LAYER 1: BAR CONTENT (Clock / Idle Widget)
    // Fades out completely when notification or popup opens
    // ==========================================
    Item {
        id: barContentContainer

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.idleW
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

    // ==========================================
    // LAYER 2: NOTIFICATION CONTENT
    // ==========================================
    Item {
        id: notifContentContainer

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 0
        width: Math.max(0, root.smoothNotifW - (root.flareW * 2) - 8)
        height: Math.max(0, root.smoothNotifH - 14)
        opacity: {
            if (root.notifProgress <= 0.001)
                return 0;

            if (root.openProgress > 0)
                return Math.min(1, Math.max(0, (0.35 - root.openProgress) / 0.35)) * root.notifProgress;

            return root.notifProgress;
        }
        scale: {
            if (root.openProgress > 0)
                return 0.95 + 0.05 * Math.min(1, Math.max(0, (0.35 - root.openProgress) / 0.35));

            return 0.95 + 0.05 * root.notifProgress;
        }
        visible: opacity > 0.001
        clip: true

        Item {
            id: slotAHolder

            anchors.fill: parent
            opacity: 1
            scale: 1
            visible: opacity > 0.001

            NotificationsModule.NotificationDelegateContent {
                id: contentA

                anchors.fill: parent
                notifData: root.notifDataA
                expanded: root.expanded
                isConvex: true
            }

            transform: Translate {
                id: slotATranslate

                y: 0
            }

        }

        Item {
            id: slotBHolder

            anchors.fill: parent
            opacity: 0
            scale: 0.98
            visible: opacity > 0.001

            NotificationsModule.NotificationDelegateContent {
                id: contentB

                anchors.fill: parent
                notifData: root.notifDataB
                expanded: root.expanded
                isConvex: true
            }

            transform: Translate {
                id: slotBTranslate

                y: 4
            }

        }

        transform: Translate {
            x: root.dragOffset
        }

    }

    // ==========================================
    // LAYER 3: MUSIC POPUP (MiniMusicWidget)
    // ==========================================
    Item {
        id: musicContentContainer

        anchors.fill: parent
        anchors.leftMargin: root.flareW + root.contentPadding
        anchors.rightMargin: root.flareW + root.contentPadding
        anchors.topMargin: root.contentPadding
        anchors.bottomMargin: root.contentPadding
        clip: true
        opacity: root.isClosing ? Math.min(1, Math.max(0, (root.openProgress - 0.4) / 0.6)) : Math.min(1, Math.max(0, (root.openProgress - 0.2) / 0.8))
        scale: root.isClosing ? (0.94 + 0.06 * Math.min(1, Math.max(0, (root.openProgress - 0.3) / 0.7))) : (0.94 + 0.06 * Math.min(1, Math.max(0, (root.openProgress - 0.15) / 0.85)))
        visible: opacity > 0.001

        Loader {
            id: musicLoader

            anchors.fill: parent
            active: root.isOpen || root.openProgress > 0.001

            sourceComponent: Component {
                MusicModule.MiniMusicWidget {
                    widget: root
                }

            }

        }

    }

    // ==========================================
    // ANIMATIONS & BEHAVIORS
    // ==========================================
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

    Behavior on openProgress {
        enabled: HyprlandService.enableAnimations

        NumberAnimation {
            duration: root.isClosing ? Constants.animNormal : Constants.animExpressive
            easing.type: root.isClosing ? Easing.OutCubic : Easing.OutQuint
            onRunningChanged: {
                if (!running && root.isClosing)
                    root.finishClosingMusic();

            }
        }

    }

    Behavior on notifProgress {
        enabled: HyprlandService.enableAnimations

        NumberAnimation {
            duration: root.isRemovingNotif ? Constants.animFast : Constants.animExpressive
            easing.type: root.isRemovingNotif ? Easing.OutCubic : Easing.OutQuint
            onRunningChanged: {
                if (!running && root.isRemovingNotif) {
                    root.isRemovingNotif = false;
                    root.dismissActiveNotifications();
                }
            }
        }

    }

    Behavior on smoothMusicW {
        enabled: HyprlandService.enableAnimations && root.openProgress >= 0.85

        NumberAnimation {
            duration: Constants.animSlow
            easing.type: Easing.OutQuint
        }

    }

    Behavior on smoothMusicH {
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

}
