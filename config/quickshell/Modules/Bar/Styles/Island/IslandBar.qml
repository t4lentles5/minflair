import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Bar.Widgets.Dashboard as DashboardModule
import qs.Modules.Clipboard as ClipboardModule
import qs.Modules.ControlCenter as ControlCenterModule
import qs.Modules.Launcher as LauncherModule
import qs.Modules.MusicPopup as MusicModule
import qs.Modules.Notifications as NotificationsModule
import qs.Modules.WallpaperSelector as WallpaperModule

Item {
    id: islandBar

    required property var notificationService
    property var mainPanelWidget: null
    readonly property string currentPopup: AppState.activePopup
    readonly property bool isHostPopup: SettingsService.barIslandMode && (currentPopup === "dashboard" || currentPopup === "controlCenter" || currentPopup === "music" || currentPopup === "launcher" || currentPopup === "clipboard" || currentPopup === "wallpaper")
    property string activePopupName: ""
    readonly property var activeItem: loaderA ? loaderA.item : null
    readonly property string effectivePopup: (AppState.activePopup !== "" && islandBar.isHostPopup) ? AppState.activePopup : activePopupName
    property bool isOpen: false
    property bool isRemoving: false
    readonly property bool isOverlayActive: isOpen || (islandRect && islandRect.openProgress > 0.001) || isRemoving
    readonly property bool needsFocus: (effectivePopup === "launcher" || effectivePopup === "clipboard" || effectivePopup === "wallpaper")
    // Notifications logic
    readonly property var currentNotifItem: (notificationService && notificationService.activeList && notificationService.activeList.count > 0) ? notificationService.activeList.get(0) : null
    readonly property var currentNotifData: currentNotifItem ? currentNotifItem.notifData : null
    readonly property bool hasActiveNotifications: currentNotifData !== null
    property string activeSlot: "A"
    property var notifDataA: null
    property var notifDataB: null
    property bool _isPruning: false
    property bool wasPausedByHostPopup: false
    readonly property bool isOccupied: isOverlayActive || hasActiveNotifications
    // Bar Style Interface
    readonly property real leftWidth: 0
    readonly property real rightWidth: 0
    readonly property real centerX: x
    readonly property real centerWidth: width
    readonly property bool isExpanded: SettingsService.barIslandExpanded
    readonly property string activeBarStyle: "island"
    // Geometry exposed for popupSurface mask
    readonly property real blockX: islandRect ? (islandBar.x + islandRect.x) : 0
    readonly property real blockY: islandRect ? islandRect.y : 0
    readonly property real blockWidth: islandRect ? islandRect.width : 0
    readonly property real blockHeight: islandRect ? islandRect.height : 0
    readonly property real currentHeight: islandRect ? islandRect.height : 36

    function syncDimensions() {
        if (islandRect.width > 0) {
            AppState.barIslandWidth = islandRect.width;
            if (!isOccupied)
                AppState.islandWidth = islandRect.width;

        }
        if (islandRect.height > 0) {
            AppState.barIslandHeight = islandRect.height;
            if (!isOccupied)
                AppState.islandHeight = islandRect.height;

        }
    }

    function getComponent(popup) {
        switch (popup) {
        case "dashboard":
            return dashboardComp;
        case "controlCenter":
            return controlCenterComp;
        case "music":
            return musicComp;
        case "launcher":
            return launcherComp;
        case "clipboard":
            return clipboardComp;
        case "wallpaper":
            return wallpaperComp;
        default:
            return null;
        }
    }

    function getTargetPadding(popup) {
        if (popup === "")
            return 0;

        return Constants.sizeLg;
    }

    function getTargetWidth(popup, item) {
        let pad = getTargetPadding(popup);
        if (item && item.implicitWidth > 0)
            return item.implicitWidth + (pad * 2);

        let w = Math.round(islandContent.implicitWidth) + 24;
        return (w % 2 === 0) ? w : (w + 1);
    }

    function getTargetHeight(popup, item) {
        let pad = getTargetPadding(popup);
        if (item && item.implicitHeight > 0)
            return item.implicitHeight + (pad * 2);

        return 36;
    }

    function getContentWidth(popup, item) {
        let pad = getTargetPadding(popup);
        return Math.max(0, getTargetWidth(popup, item) - (pad * 2));
    }

    function getContentHeight(popup, item) {
        let pad = getTargetPadding(popup);
        return Math.max(0, getTargetHeight(popup, item) - (pad * 2));
    }

    function getTargetRadius(popup) {
        if (popup === "")
            return getTargetHeight("", null) / 2;

        return Constants.size3Xl;
    }

    function getNotifTargetWidth(notifData) {
        return 380;
    }

    function getNotifTargetHeight(contentItem) {
        let h = contentItem ? contentItem.implicitHeight : 0;
        let baseH = getTargetHeight("", null);
        return Math.max(h + Constants.sizeSm * 2 + 4, baseH);
    }

    function updateContent(newPopup) {
        if (!SettingsService.barIslandMode) {
            closeImmediately();
            return ;
        }
        let isHost = (newPopup === "dashboard" || newPopup === "controlCenter" || newPopup === "music" || newPopup === "launcher" || newPopup === "clipboard" || newPopup === "wallpaper");
        if (!isHost) {
            if (isOpen)
                close();

            return ;
        }
        let comp = getComponent(newPopup);
        if (!comp)
            return ;

        if (activePopupName !== newPopup) {
            loaderA.sourceComponent = comp;
            activePopupName = newPopup;
        }
        if (!isOpen) {
            isOpen = true;
            focusTimer.restart();
        }
    }

    function close() {
        if (isRemoving)
            return ;

        isRemoving = true;
        isOpen = false;
        if (islandRect)
            islandRect.openProgress = 0;

        if (!HyprlandService.enableAnimations)
            finishClosing();

    }

    function finishClosing() {
        if (isRemoving) {
            isRemoving = false;
            loaderA.sourceComponent = null;
            activePopupName = "";
            AppState.isIslandOpen = false;
            if (AppState.activePopup === effectivePopup || isHostPopup)
                AppState.activePopup = "";

            if (hasActiveNotifications && !islandRect.isRemovingNotif)
                islandDisplayTimer.restart();

        }
    }

    function closeImmediately() {
        isRemoving = false;
        isOpen = false;
        if (islandRect)
            islandRect.openProgress = 0;

        loaderA.sourceComponent = null;
        activePopupName = "";
        AppState.isIslandOpen = false;
        if (SettingsService.barIslandMode && isHostPopup)
            AppState.activePopup = "";

    }

    function requestFocus() {
        if (!needsFocus)
            return ;

        let it = activeItem;
        if (it) {
            if (it.resetLauncher)
                it.resetLauncher();
            else if (it.resetClipboard)
                it.resetClipboard();
            else if (it.resetWallpaperSelector)
                it.resetWallpaperSelector();
            if (it.initialFocusItem) {
                if (it.initialFocusItem.textField)
                    it.initialFocusItem.textField.forceActiveFocus();
                else
                    it.initialFocusItem.forceActiveFocus();
            } else {
                it.forceActiveFocus();
            }
        }
    }

    // Notifications Logic
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
        if (islandRect)
            islandRect.dragOffset = 0;

    }

    function closeNotification() {
        if (islandRect.isRemovingNotif || !currentNotifData)
            return ;

        islandRect.isRemovingNotif = true;
        islandDisplayTimer.stop();
    }

    function closeNotificationImmediately() {
        islandRect.isRemovingNotif = true;
        islandDisplayTimer.stop();
        islandRect.dragOffset = 0;
        islandRect.isRemovingNotif = false;
        dismissActiveNotifications();
    }

    onWidthChanged: syncDimensions()
    onHeightChanged: syncDimensions()
    Component.onCompleted: syncDimensions()
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    implicitWidth: islandRect.width
    height: islandRect.height
    onIsOpenChanged: {
        if (isOpen) {
            AppState.isIslandOpen = true;
            isRemoving = false;
            islandRect.openProgress = 1;
            focusTimer.restart();
            Qt.callLater(requestFocus);
        } else {
            close();
        }
    }
    onHasActiveNotificationsChanged: {
        if (SettingsService.barIslandMode) {
            let active = hasActiveNotifications && !islandRect.isRemovingNotif;
            AppState.hasActiveNotification = active;
            if (active) {
                AppState.activeNotificationWidth = islandRect.notifW;
                AppState.activeNotificationHeight = islandRect.notifH;
            } else {
                AppState.activeNotificationWidth = 0;
                AppState.activeNotificationHeight = 0;
            }
        }
    }
    onCurrentNotifDataChanged: {
        Qt.callLater(pruneActiveNotifications);
        if (currentNotifData) {
            islandRect.isRemovingNotif = false;
            islandRect.dragOffset = 0;
            // If it is the first notification, activeSlot is A, else transition
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
            islandDisplayTimer.restart();
        }
    }

    Connections {
        function onActivePopupChanged() {
            if (SettingsService.barIslandMode)
                updateContent(AppState.activePopup);

        }

        target: AppState
    }

    Connections {
        function onBarIslandModeChanged() {
            if (!SettingsService.barIslandMode)
                closeImmediately();
            else
                updateContent(AppState.activePopup);
        }

        target: SettingsService
    }

    Timer {
        id: focusTimer

        interval: 40
        repeat: false
        onTriggered: {
            requestFocus();
            focusRetryTimer.restart();
        }
    }

    Timer {
        id: focusRetryTimer

        interval: 100
        repeat: false
        onTriggered: requestFocus()
    }

    Connections {
        function onCountChanged() {
            Qt.callLater(pruneActiveNotifications);
        }

        target: (notificationService && notificationService.activeList) ? notificationService.activeList : null
    }

    Timer {
        id: islandDisplayTimer

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
        running: hasActiveNotifications && !islandRect.isRemovingNotif && !islandRect.isHovered && interval > 0 && !isHostPopup
        repeat: false
        onTriggered: closeNotification()
    }

    IslandBackground {
        id: islandRect

        property bool isRemovingNotif: false
        property real dragOffset: 0
        property bool isHovered: mainMouseArea.containsMouse
        property bool expanded: false
        property real openProgress: 0
        property real notifProgress: (hasActiveNotifications && !isRemovingNotif) ? 1 : 0
        readonly property real idleW: getTargetWidth("", null)
        readonly property real idleH: getTargetHeight("", null)
        readonly property real idleR: getTargetRadius("")
        readonly property real popupW: getTargetWidth(effectivePopup, activeItem)
        readonly property real popupH: getTargetHeight(effectivePopup, activeItem)
        readonly property real popupR: getTargetRadius(effectivePopup)
        readonly property real notifW: getNotifTargetWidth(activeSlot === "A" ? notifDataA : notifDataB)
        readonly property real notifH: getNotifTargetHeight(activeSlot === "A" ? contentA : contentB)
        readonly property real notifR: Constants.sizeSm
        property real smoothPopupW: popupW
        property real smoothPopupH: popupH
        property real smoothPopupR: popupR
        property real smoothNotifW: notifW
        property real smoothNotifH: notifH
        readonly property real baseW: idleW + (smoothNotifW - idleW) * islandRect.notifProgress
        readonly property real baseH: idleH + (smoothNotifH - idleH) * islandRect.notifProgress
        readonly property real baseR: idleR + (notifR - idleR) * islandRect.notifProgress
        readonly property real currentWidth: baseW + (smoothPopupW - baseW) * islandRect.openProgress
        readonly property real currentHeight: baseH + (smoothPopupH - baseH) * islandRect.openProgress
        readonly property real currentRadius: baseR + (smoothPopupR - baseR) * islandRect.openProgress

        onCurrentWidthChanged: syncDimensions()
        onCurrentHeightChanged: syncDimensions()
        onExpandedChanged: {
            let d = (activeSlot === "A" ? notifDataA : notifDataB) || currentNotifData;
            if (d) {
                if (expanded)
                    d.lock("expanded");
                else
                    d.unlock("expanded");
            }
        }
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: currentWidth
        height: currentHeight
        radius: currentRadius
        enableShadow: true
        Keys.forwardTo: {
            if (!needsFocus || !activeItem || !activeItem.initialFocusItem)
                return [];

            let it = activeItem.initialFocusItem;
            if (it.textField)
                return [it.textField, it];

            return [it];
        }
        Keys.enabled: isOpen && needsFocus
        Keys.onEscapePressed: close()

        Connections {
            function onPopupChanged() {
                let d = (activeSlot === "A" ? notifDataA : notifDataB) || currentNotifData;
                if (d && !d.popup && !islandRect.isRemovingNotif)
                    closeNotification();

            }

            target: (activeSlot === "A" ? notifDataA : notifDataB) || currentNotifData
        }

        MouseArea {
            // Let popup handle its clicks

            id: mainMouseArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: (islandRect.notifProgress > 0 && islandRect.openProgress === 0) ? Qt.PointingHandCursor : Qt.ArrowCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onEntered: {
                let d = (activeSlot === "A" ? notifDataA : notifDataB) || currentNotifData;
                if (d && islandRect.notifProgress > 0 && islandRect.openProgress === 0)
                    d.lock(islandRect);

            }
            onExited: {
                let d = (activeSlot === "A" ? notifDataA : notifDataB) || currentNotifData;
                if (d && islandRect.notifProgress > 0 && islandRect.openProgress === 0)
                    d.unlock(islandRect);

            }
            onClicked: (mouse) => {
                if (islandRect.openProgress > 0) {
                } else if (islandRect.notifProgress > 0) {
                    if (mouse.button === Qt.LeftButton)
                        closeNotificationImmediately();
                    else
                        closeNotification();
                } else {
                    if (mouse.button === Qt.RightButton)
                        SettingsService.barIslandExpanded = !SettingsService.barIslandExpanded;

                }
            }
        }

        DragHandler {
            id: dragHandler

            target: null
            xAxis.enabled: islandRect.notifProgress > 0 && islandRect.openProgress === 0
            yAxis.enabled: islandRect.notifProgress > 0 && islandRect.openProgress === 0
            onTranslationChanged: {
                if (islandRect.notifProgress === 0 || islandRect.openProgress > 0)
                    return ;

                if (Math.abs(translation.x) > Math.abs(translation.y))
                    islandRect.dragOffset = translation.x;
                else if (translation.y < -15)
                    closeNotification();
            }
            onActiveChanged: {
                if (!active) {
                    if (Math.abs(islandRect.dragOffset) > islandRect.width / 4)
                        closeNotification();
                    else
                        snapBackAnim.restart();
                }
            }
        }

        NumberAnimation {
            id: snapBackAnim

            target: islandRect
            property: "dragOffset"
            to: 0
            duration: Constants.animFast
            easing.type: Easing.OutBack
        }

        // Layer 1: Bar Content
        Item {
            id: barContentContainer

            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: islandRect.idleW
            height: islandRect.idleH
            opacity: {
                let p = Math.max(islandRect.openProgress, islandRect.notifProgress);
                return Math.min(1, Math.max(0, 1 - p / 0.15));
            }
            scale: {
                let p = Math.max(islandRect.openProgress, islandRect.notifProgress);
                return 1 - 0.04 * Math.min(1, p / 0.15);
            }
            visible: opacity > 0.001
            clip: true

            IslandContent {
                id: islandContent

                anchors.centerIn: parent
                notificationService: islandBar.notificationService
                widget: islandBar.mainPanelWidget
                mainBar: islandBar
            }

        }

        // Layer 2: Notification Content
        Item {
            id: notifContentContainer

            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 0
            width: islandRect.smoothNotifW
            height: islandRect.smoothNotifH
            opacity: {
                if (islandRect.notifProgress <= 0.001)
                    return 0;

                if (islandRect.openProgress > 0)
                    return Math.min(1, Math.max(0, (0.35 - islandRect.openProgress) / 0.35)) * islandRect.notifProgress;

                return islandRect.notifProgress;
            }
            scale: {
                if (islandRect.openProgress > 0)
                    return 0.95 + 0.05 * Math.min(1, Math.max(0, (0.35 - islandRect.openProgress) / 0.35));

                return 0.95 + 0.05 * islandRect.notifProgress;
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
                    notifData: notifDataA
                    expanded: islandRect.expanded
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
                    notifData: notifDataB
                    expanded: islandRect.expanded
                }

                transform: Translate {
                    id: slotBTranslate

                    y: 4
                }

            }

        }

        // Layer 3: Popup Content
        Item {
            id: popupContentContainer

            anchors.fill: parent
            anchors.margins: getTargetPadding(effectivePopup)
            clip: true
            opacity: isRemoving ? Math.min(1, Math.max(0, (islandRect.openProgress - 0.4) / 0.6)) : Math.min(1, Math.max(0, (islandRect.openProgress - 0.2) / 0.8))
            scale: isRemoving ? (0.94 + 0.06 * Math.min(1, Math.max(0, (islandRect.openProgress - 0.3) / 0.7))) : (0.94 + 0.06 * Math.min(1, Math.max(0, (islandRect.openProgress - 0.15) / 0.85)))
            visible: opacity > 0.001

            Loader {
                id: loaderA

                property real targetW: getContentWidth(activePopupName, item)
                property real targetH: getContentHeight(activePopupName, item)

                width: targetW > 0 ? targetW : parent.width
                height: targetH > 0 ? targetH : parent.height
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                onStatusChanged: {
                    if (status === Loader.Ready && item) {
                        if (item.widget !== undefined)
                            item.widget = islandBar;

                        focusTimer.restart();
                        Qt.callLater(requestFocus);
                    }
                }
            }

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

        Behavior on notifProgress {
            enabled: HyprlandService.enableAnimations

            NumberAnimation {
                duration: islandRect.isRemovingNotif ? Constants.animNormal : Constants.animExpressive
                easing.type: islandRect.isRemovingNotif ? Easing.OutCubic : Easing.OutQuint
                onRunningChanged: {
                    if (!running && islandRect.isRemovingNotif) {
                        islandRect.isRemovingNotif = false;
                        dismissActiveNotifications();
                    }
                }
            }

        }

        Behavior on openProgress {
            enabled: HyprlandService.enableAnimations

            NumberAnimation {
                duration: isRemoving ? Constants.animNormal : Constants.animExpressive
                easing.type: isRemoving ? Easing.OutCubic : Easing.OutQuint
                onRunningChanged: {
                    if (!running && isRemoving)
                        finishClosing();

                }
            }

        }

        Behavior on smoothPopupW {
            enabled: HyprlandService.enableAnimations && islandRect.openProgress >= 0.85

            NumberAnimation {
                duration: Constants.animSlow
                easing.type: Easing.OutQuint
            }

        }

        Behavior on smoothPopupH {
            enabled: HyprlandService.enableAnimations && islandRect.openProgress >= 0.85

            NumberAnimation {
                duration: Constants.animSlow
                easing.type: Easing.OutQuint
            }

        }

        Behavior on smoothPopupR {
            enabled: HyprlandService.enableAnimations && islandRect.openProgress >= 0.85

            NumberAnimation {
                duration: Constants.animSlow
                easing.type: Easing.OutQuint
            }

        }

        Behavior on smoothNotifW {
            enabled: HyprlandService.enableAnimations && islandRect.notifProgress >= 0.85

            NumberAnimation {
                duration: Constants.animSlow
                easing.type: Easing.OutQuint
            }

        }

        Behavior on smoothNotifH {
            enabled: HyprlandService.enableAnimations && islandRect.notifProgress >= 0.85

            NumberAnimation {
                duration: Constants.animSlow
                easing.type: Easing.OutQuint
            }

        }

        transform: Translate {
            x: islandRect.dragOffset
        }

    }

    Component {
        id: dashboardComp

        DashboardModule.DashboardContent {
            widget: islandBar
        }

    }

    Component {
        id: controlCenterComp

        ControlCenterModule.ControlCenterContent {
            widget: islandBar
            notificationService: islandBar.notificationService
            isHorizontal: true
        }

    }

    Component {
        id: musicComp

        MusicModule.MiniMusicWidget {
            widget: islandBar
        }

    }

    Component {
        id: launcherComp

        LauncherModule.LauncherContent {
            widget: islandBar
        }

    }

    Component {
        id: clipboardComp

        ClipboardModule.ClipboardContent {
            widget: islandBar
        }

    }

    Component {
        id: wallpaperComp

        WallpaperModule.WallpaperSelectorContent {
            widget: islandBar
        }

    }

}
