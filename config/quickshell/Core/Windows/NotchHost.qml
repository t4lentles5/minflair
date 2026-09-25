import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Core.Windows.Components
import qs.Modules.Bar.Components

Item {
    id: root

    property var notificationService: null

    visible: crossfadeHost.isOverlayActive

    PopupCrossfadeHost {
        id: crossfadeHost

        anchors.fill: parent
        notificationService: root.notificationService
        barMode: "notch"
        visualContainer: notchContainer
        contentHorizontalPadding: 18 + Constants.sizeLg // flareW + contentPadding
        contentVerticalPadding: Constants.sizeLg // contentPadding
        defaultWidth: (AppState.barNotchWidth > 0) ? AppState.barNotchWidth : 220
        defaultHeight: (AppState.barNotchHeight > 0) ? AppState.barNotchHeight : 36
    }

    Item {
        id: notchContainer

        property real fromWidth: crossfadeHost.defaultWidth
        property real fromHeight: crossfadeHost.defaultHeight
        readonly property real targetW: crossfadeHost.getTargetWidth(crossfadeHost.effectivePopup, crossfadeHost.activeItem)
        readonly property real targetH: crossfadeHost.getTargetHeight(crossfadeHost.effectivePopup, crossfadeHost.activeItem)
        property real smoothTargetW: targetW
        property real smoothTargetH: targetH
        property real openProgress: 0
        readonly property real currentWidth: Math.round(fromWidth + (smoothTargetW - fromWidth) * openProgress)
        readonly property real currentHeight: Math.round(fromHeight + (smoothTargetH - fromHeight) * openProgress)

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: currentWidth
        height: currentHeight
        clip: false
        visible: crossfadeHost.isOverlayActive
        focus: crossfadeHost.needsFocus
        Keys.enabled: crossfadeHost.needsFocus
        Keys.onEscapePressed: crossfadeHost.close()

        MouseArea {
            anchors.fill: parent
        }

        NotchShape {
            id: notchBg

            anchors.fill: parent
            color: Theme.bg
            flareWidth: 18
            flareHeight: 16
            topBezel: 0
            bottomRadius: 16 + (Constants.size3Xl - 16) * notchContainer.openProgress
            enableShadow: SettingsService.barNotchMode && !crossfadeHost.isHandover
        }

        Item {
            id: barSlotHolder

            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: notchContainer.fromWidth
            height: notchContainer.fromHeight
            clip: true
            visible: opacity > 0.001
            opacity: crossfadeHost.isHandover ? 1 : (crossfadeHost.isRemoving ? Math.min(1, Math.max(0, (1 - notchContainer.openProgress) / 0.7)) : 0)
            transformOrigin: Item.Top

            QtObject {
                id: dummyNotchBar

                property string activeBarStyle: "notch"
                property bool isExpanded: false
            }

            BarCenterContent {
                anchors.centerIn: parent
                mainBar: dummyNotchBar
                notificationService: root.notificationService
            }

        }

        Item {
            id: contentArea

            anchors.fill: parent
            anchors.leftMargin: 18 + Constants.sizeLg
            anchors.rightMargin: 18 + Constants.sizeLg
            anchors.topMargin: Constants.sizeLg
            anchors.bottomMargin: Constants.sizeLg
            clip: true
            opacity: crossfadeHost.isRemoving ? Math.min(1, Math.max(0, (notchContainer.openProgress - 0.4) / 0.6)) : Math.min(1, Math.max(0, (notchContainer.openProgress - 0.2) / 0.8))
            scale: crossfadeHost.isRemoving ? (0.94 + 0.06 * Math.min(1, Math.max(0, (notchContainer.openProgress - 0.3) / 0.7))) : (0.94 + 0.06 * Math.min(1, Math.max(0, (notchContainer.openProgress - 0.15) / 0.85)))
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

                        crossfadeHost.contentLoader.item = item;
                        crossfadeHost.requestFocus();
                    }
                }
            }

        }

        Behavior on smoothTargetW {
            enabled: HyprlandService.enableAnimations && notchContainer.openProgress >= 0.85

            NumberAnimation {
                duration: Constants.animSlow
                easing.type: Easing.OutQuint
            }

        }

        Behavior on smoothTargetH {
            enabled: HyprlandService.enableAnimations && notchContainer.openProgress >= 0.85

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
