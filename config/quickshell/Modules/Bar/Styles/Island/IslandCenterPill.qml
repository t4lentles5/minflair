import QtQuick
import qs.Core
import qs.Core.Components
import qs.Core.Services

IslandBackground {
    id: root

    required property QtObject islandBar
    required property QtObject islandComponents
    required property Item islandContainer
    required property var notificationService
    property real openProgress: 0
    readonly property bool isTarget: islandBar.activeIslandTarget === "center" && (islandBar.isOpen || islandBar.isRemoving)
    readonly property bool hasActiveNotifications: notifLayer.hasActiveNotifications
    readonly property bool isRemovingNotif: notifLayer.isRemovingNotif
    property real notifProgress: (hasActiveNotifications && !isRemovingNotif) ? 1 : 0
    readonly property bool isHovered: centerHover.hovered && !islandBar.isOpen && openProgress === 0 && !hasActiveNotifications
    readonly property bool isTranslated: isHovered || isTarget || openProgress > 0 || (hasActiveNotifications && notifProgress > 0)
    readonly property real notifW: notifLayer.notifW
    readonly property real notifH: notifLayer.notifH
    readonly property real notifR: Constants.sizeXl
    readonly property real idleW: clockContent.implicitWidth + 20
    readonly property real idleH: Constants.size3Xl
    readonly property real idleR: Constants.sizeLg
    property real smoothIdleW: idleW
    readonly property real panelW: isTarget ? islandComponents.getTargetWidth(islandBar.effectivePanel, centerLoader.item, 0) : smoothIdleW
    readonly property real panelH: isTarget ? islandComponents.getTargetHeight(islandBar.effectivePanel, centerLoader.item) : idleH
    readonly property real panelR: isTarget ? islandComponents.getTargetRadius(islandBar.effectivePanel) : idleR
    readonly property real baseW: smoothIdleW + (notifW - smoothIdleW) * notifProgress
    readonly property real baseH: idleH + (notifH - idleH) * notifProgress
    readonly property real baseR: idleR + (notifR - idleR) * notifProgress
    property real smoothPanelW: panelW
    property real smoothPanelH: panelH
    property real smoothPanelR: panelR
    readonly property alias activeItem: centerLoader.item

    function restartDisplayTimer() {
        notifLayer.restartDisplayTimer();
    }

    z: isTarget ? 10 : 1
    x: Math.round((islandContainer.width - width) / 2)
    y: 0
    width: baseW + (smoothPanelW - baseW) * openProgress
    height: baseH + (smoothPanelH - baseH) * openProgress
    radius: baseR + (smoothPanelR - baseR) * openProgress

    HoverHandler {
        id: centerHover

        enabled: !islandBar.isOpen && root.openProgress === 0 && !root.hasActiveNotifications
        margin: root.isHovered ? 8 : 0
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        enabled: root.openProgress > 0.05
    }

    IslandClock {
        id: clockContent

        anchors.centerIn: parent
        opacity: Math.min(1, Math.max(0, 1 - Math.max(root.openProgress, root.notifProgress) / 0.15))
        visible: opacity > 0.001
        clickable: !islandBar.isOpen && !root.hasActiveNotifications
    }

    IslandNotifLayer {
        id: notifLayer

        notificationService: root.notificationService
        isHostPanel: islandBar.isHostPanel
        openProgress: root.openProgress
        notifProgress: root.notifProgress
        anchors.centerIn: parent
        width: parent.width
        height: parent.height
    }

    Item {
        anchors.fill: parent
        anchors.margins: islandComponents.getTargetPadding(islandBar.effectivePanel)
        opacity: islandBar.isRemoving ? Math.min(1, Math.max(0, (root.openProgress - 0.4) / 0.6)) : Math.min(1, Math.max(0, (root.openProgress - 0.2) / 0.8))
        scale: islandBar.isRemoving ? (0.94 + 0.06 * Math.min(1, Math.max(0, (root.openProgress - 0.3) / 0.7))) : (0.94 + 0.06 * Math.min(1, Math.max(0, (root.openProgress - 0.15) / 0.85)))
        visible: opacity > 0.001
        clip: true

        Loader {
            id: centerLoader

            property real targetW: islandComponents.getContentWidth(islandBar.effectivePanel, item)
            property real targetH: islandComponents.getContentHeight(islandBar.effectivePanel, item)

            width: targetW > 0 ? targetW : parent.width
            height: targetH > 0 ? targetH : parent.height
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            active: root.isTarget
            sourceComponent: islandComponents.getComponent(islandBar.effectivePanel)
            opacity: status === Loader.Ready ? 1 : 0
            onStatusChanged: {
                if (status === Loader.Ready && item) {
                    if (item.widget !== undefined)
                        item.widget = islandBar;

                    islandBar.triggerFocus();
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: Constants.animFast
                    easing.type: Easing.OutCubic
                }

            }

        }

    }

    transform: Translate {
        y: root.isTranslated ? 4 : 0

        Behavior on y {
            enabled: HyprlandService.enableAnimations

            NumberAnimation {
                duration: Constants.animNormal
                easing.type: Easing.OutQuint
            }

        }

    }

    Behavior on smoothIdleW {
        enabled: HyprlandService.enableAnimations

        NumberAnimation {
            duration: Constants.animNormal
            easing.type: Easing.OutQuint
        }

    }

    Behavior on smoothPanelW {
        enabled: HyprlandService.enableAnimations && root.openProgress >= 0.85

        NumberAnimation {
            duration: Constants.animSlow
            easing.type: Easing.OutQuint
        }

    }

    Behavior on smoothPanelH {
        enabled: HyprlandService.enableAnimations && root.openProgress >= 0.85

        NumberAnimation {
            duration: Constants.animSlow
            easing.type: Easing.OutQuint
        }

    }

    Behavior on smoothPanelR {
        enabled: HyprlandService.enableAnimations && root.openProgress >= 0.85

        NumberAnimation {
            duration: Constants.animSlow
            easing.type: Easing.OutQuint
        }

    }

    Behavior on notifProgress {
        enabled: HyprlandService.enableAnimations

        NumberAnimation {
            duration: root.isRemovingNotif ? Constants.animFast : Constants.animNormal
            easing.type: Easing.OutCubic
            onRunningChanged: {
                if (!running && root.isRemovingNotif) {
                    notifLayer.isRemovingNotif = false;
                    notifLayer.dismissActiveNotifications();
                }
            }
        }

    }

    Behavior on openProgress {
        enabled: HyprlandService.enableAnimations

        NumberAnimation {
            duration: islandBar.isRemoving ? Constants.animNormal : Constants.animExpressive
            easing.type: islandBar.isRemoving ? Easing.OutCubic : Easing.OutQuint
            onRunningChanged: {
                if (!running && islandBar.isRemoving)
                    islandBar.checkFinishClosing();

            }
        }

    }

}
