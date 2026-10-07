import QtQuick
import qs.Core
import qs.Modules.Notifications as NotificationsModule

Item {
    id: root

    required property var notificationService
    property string lockScope: "bar"
    property bool isExpandedOpen: false
    property bool isConvex: false
    property int flareW: 0
    property real openProgress: 0
    property bool isRemovingNotif: false
    property real dragOffset: 0
    readonly property bool isHovered: (notifHoverHandler.hovered || notifMouseArea.containsMouse) && root.notifProgress > 0 && root.openProgress === 0
    property bool effectiveHover: false
    readonly property var currentNotifItem: (notificationService && notificationService.activeList && notificationService.activeList.count > 0) ? notificationService.activeList.get(0) : null
    readonly property var currentNotifData: currentNotifItem ? currentNotifItem.notifData : null
    readonly property bool hasActiveNotifications: currentNotifData !== null
    property real notifProgress: 0
    readonly property real notifW: 380 + (flareW * 2)
    readonly property real notifH: {
        let activeContent = activeSlot === "A" ? contentA : contentB;
        let h = activeContent ? activeContent.implicitHeight : 0;
        let extraH = isConvex ? 14 : 4;
        let minH = isConvex ? 76 : 36;
        return Math.max(h + Constants.sizeSm * 2 + extraH, minH);
    }
    property string activeSlot: "A"
    property var notifDataA: null
    property var notifDataB: null
    property bool _isPruning: false
    property real remainingTimeRatio: 1

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
        let d = (activeSlot === "A" ? notifDataA : notifDataB) || currentNotifData;
        if (root.isRemovingNotif || !currentNotifData || root.effectiveHover || root.isHovered || (d && d.isLocked))
            return ;

        root.isRemovingNotif = true;
        displayTimer.stop();
    }

    function closeNotificationImmediately() {
        unhoverDebounceTimer.stop();
        effectiveHover = false;
        root.isRemovingNotif = true;
        displayTimer.stop();
        root.dragOffset = 0;
        let d = (activeSlot === "A" ? notifDataA : notifDataB) || currentNotifData;
        if (d)
            d.unlock(root.lockScope);

        root.isRemovingNotif = false;
        dismissActiveNotifications();
    }

    function restartDisplayTimer() {
        if (!root.isHovered)
            displayTimer.restart();

    }

    onIsHoveredChanged: {
        let d = (activeSlot === "A" ? notifDataA : notifDataB) || currentNotifData;
        if (isHovered) {
            unhoverDebounceTimer.stop();
            effectiveHover = true;
            displayTimer.stop();
            if (d)
                d.lock(root.lockScope);

        } else {
            unhoverDebounceTimer.restart();
        }
    }
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
            if (!root.effectiveHover && !root.isHovered) {
                root.remainingTimeRatio = 1;
                displayTimer.restart();
            } else {
                displayTimer.stop();
                currentNotifData.lock(root.lockScope);
            }
        }
    }
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

    Timer {
        id: unhoverDebounceTimer

        interval: 350
        repeat: false
        onTriggered: {
            if (!root.isHovered) {
                root.effectiveHover = false;
                let d = (activeSlot === "A" ? notifDataA : notifDataB) || currentNotifData;
                if (d) {
                    d.unlock(root.lockScope);
                    root.remainingTimeRatio = (d.progress !== undefined) ? Math.max(0.05, Math.min(1, d.progress)) : 1;
                } else {
                    root.remainingTimeRatio = 1;
                }
                if (hasActiveNotifications && !isRemovingNotif && !isExpandedOpen)
                    displayTimer.restart();

            }
        }
    }

    Connections {
        function onCountChanged() {
            Qt.callLater(pruneActiveNotifications);
        }

        target: (notificationService && notificationService.activeList) ? notificationService.activeList : null
    }

    Connections {
        function onPopupChanged() {
            let d = (activeSlot === "A" ? notifDataA : notifDataB) || currentNotifData;
            if (d && !d.popup && !root.effectiveHover && !root.isHovered && !d.isLocked)
                closeNotification();

        }

        target: (activeSlot === "A" ? notifDataA : notifDataB) || currentNotifData
    }

    Timer {
        id: displayTimer

        interval: {
            let d = (activeSlot === "A" ? notifDataA : notifDataB) || currentNotifData;
            if (!d)
                return Math.max(250, Math.round(5500 * root.remainingTimeRatio));

            if (d.urgency === 2)
                return -1;

            if (d.summary === "Volume" || d.summary === "Brightness" || d.summary === "Microphone")
                return Math.max(250, Math.round(1800 * root.remainingTimeRatio));

            if (d.summary === "Power Menu")
                return Math.max(250, Math.round(10000 * root.remainingTimeRatio));

            return Math.max(250, Math.round(5500 * root.remainingTimeRatio));
        }
        repeat: false
        onTriggered: {
            let d = (activeSlot === "A" ? notifDataA : notifDataB) || currentNotifData;
            if (!root.effectiveHover && !root.isHovered && (!d || !d.isLocked))
                closeNotification();

        }
    }

    HoverHandler {
        id: notifHoverHandler

        enabled: root.notifProgress > 0 && root.openProgress === 0
    }

    MouseArea {
        id: notifMouseArea

        z: 50
        anchors.fill: parent
        enabled: root.notifProgress > 0 && root.openProgress === 0
        hoverEnabled: enabled
        cursorShape: (root.notifProgress > 0 && root.openProgress === 0) ? Qt.PointingHandCursor : Qt.ArrowCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            if (root.openProgress > 0) {
            } else if (root.notifProgress > 0) {
                closeNotificationImmediately();
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
                    closeNotificationImmediately();
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
            isConvex: root.isConvex
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
            isConvex: root.isConvex
        }

        transform: Translate {
            id: slotBTranslate

            y: 4
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
                duration: Constants.animFast / 5
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

    transform: Translate {
        x: root.dragOffset
    }

}
