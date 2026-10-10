import QtQuick
import qs.Core
import qs.Core.Components
import qs.Core.Services

IslandBackground {
    id: root

    required property QtObject islandBar
    required property QtObject islandComponents
    required property Item islandContainer
    required property Item centerPill
    property real openProgress: 0
    readonly property bool isTarget: islandBar.activeIslandTarget === "right" && (islandBar.isOpen || islandBar.isRemoving)
    readonly property bool isHovered: rightHover.hovered && !islandBar.isOpen && openProgress === 0
    readonly property bool isTranslated: isHovered || isTarget || openProgress > 0
    readonly property bool hasPlayingMedia: MprisService.activePlayer !== null && (((MprisService.activePlayer.trackTitle || "").trim() !== "") || ((MprisService.activePlayer.trackArtist || "").trim() !== ""))
    readonly property bool showMedia: islandBar ? islandBar.showMediaOnRight : ((SettingsService.islandRightMode === "music") || (SettingsService.islandRightMode === "auto" && hasPlayingMedia))
    readonly property bool isMusicActive: showMedia && MprisService.isPlaying
    readonly property real targetIdleW: isMusicActive ? Constants.size5Xl + 10 : Constants.size3Xl
    property real smoothIdleW: targetIdleW
    readonly property real idleW: smoothIdleW
    readonly property real idleH: Constants.size3Xl
    readonly property real idleR: Constants.sizeLg
    readonly property real panelW: isTarget ? islandComponents.getTargetWidth(islandBar.effectivePanel, rightLoader.item, 0) : idleW
    readonly property real panelH: isTarget ? islandComponents.getTargetHeight(islandBar.effectivePanel, rightLoader.item) : idleH
    readonly property real panelR: isTarget ? islandComponents.getTargetRadius(islandBar.effectivePanel) : idleR
    readonly property alias activeItem: rightLoader.item

    z: isTarget ? 10 : 1
    x: Math.min(islandContainer.width - width - 16, centerPill.x + centerPill.width + 10)
    y: 0
    width: idleW + (panelW - idleW) * openProgress
    height: idleH + (panelH - idleH) * openProgress
    radius: idleR + (panelR - idleR) * openProgress

    HoverHandler {
        id: rightHover

        enabled: !islandBar.isOpen && root.openProgress === 0
        margin: root.isHovered ? 8 : 0
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        enabled: root.openProgress > 0.05
    }

    IslandMediaArt {
        anchors.fill: parent
        opacity: Math.min(1, Math.max(0, 1 - root.openProgress / 0.15))
        visible: opacity > 0.001
        clickable: !islandBar.isOpen
    }

    Item {
        anchors.fill: parent
        anchors.margins: Constants.sizeLg
        opacity: islandBar.isRemoving ? Math.min(1, Math.max(0, (root.openProgress - 0.4) / 0.6)) : Math.min(1, Math.max(0, (root.openProgress - 0.2) / 0.8))
        scale: islandBar.isRemoving ? (0.94 + 0.06 * Math.min(1, Math.max(0, (root.openProgress - 0.3) / 0.7))) : (0.94 + 0.06 * Math.min(1, Math.max(0, (root.openProgress - 0.15) / 0.85)))
        visible: opacity > 0.001
        clip: true

        Loader {
            id: rightLoader

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

    Behavior on smoothIdleW {
        enabled: HyprlandService.enableAnimations

        NumberAnimation {
            duration: Constants.animNormal
            easing.type: Easing.OutQuint
        }

    }

    transform: Translate {
        x: root.isTranslated ? 4 : 0
        y: root.isTranslated ? 4 : 0

        Behavior on x {
            enabled: HyprlandService.enableAnimations

            NumberAnimation {
                duration: Constants.animNormal
                easing.type: Easing.OutQuint
            }

        }

        Behavior on y {
            enabled: HyprlandService.enableAnimations

            NumberAnimation {
                duration: Constants.animNormal
                easing.type: Easing.OutQuint
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
