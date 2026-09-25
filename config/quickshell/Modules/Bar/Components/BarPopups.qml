import QtQuick
import Quickshell
import Quickshell.Services.SystemTray as QSSysTray
import qs.Core.Components
import qs.Core.Services
import qs.Core.Windows
import qs.Modules.Bar.Widgets.Dashboard
import qs.Modules.Bar.Widgets.SystemTray
import qs.Modules.ControlCenter
import qs.Modules.MusicPopup
import qs.Modules.Notifications

Item {
    id: root

    required property var notificationService
    required property int popupStartY
    property string activeBarStyle: ""
    property bool isCompact: false
    property bool usesFloatingPopups: false
    property bool hasExpandableHost: false
    property var activeHost: null
    property real barStripX: 0
    property real barStripCenterX: 0
    property real barStripCenterWidth: 0
    property alias musicLoader: musicLoader
    property alias dashboardLoader: dashboardLoader
    property alias controlCenterLoader: controlCenterLoader
    property var convexHost: null
    property alias notificationOverlay: notificationOverlay
    property var activeTrayPopup: null
    readonly property bool isFloatingPopupVisible: (usesFloatingPopups && ((dashboardLoader.item && dashboardLoader.item._visible) || (musicLoader.item && musicLoader.item._visible) || (controlCenterLoader.item && controlCenterLoader.item._visible))) || (activeTrayPopup && activeTrayPopup._visible) || (activeBarStyle === "convex" && ((dashboardLoader.item && dashboardLoader.item._visible) || (controlCenterLoader.item && controlCenterLoader.item._visible)))

    MouseArea {
        anchors.fill: parent
        enabled: (root.activeHost && root.activeHost.isOpen) || (root.usesFloatingPopups && ((dashboardLoader.item && dashboardLoader.item.isOpen) || (musicLoader.item && musicLoader.item.isOpen))) || (root.activeTrayPopup && root.activeTrayPopup.isOpen)
        onClicked: {
            if (root.activeHost && root.activeHost.isOpen)
                root.activeHost.close();

            AppState.closePopup("dashboard");
            AppState.closePopup("music");
            AppState.closePopup("controlCenter");
            if (root.activeTrayPopup && root.activeTrayPopup.isOpen)
                root.activeTrayPopup.isOpen = false;

        }
    }

    PopupLoader {
        id: musicLoader

        popupId: "music"
        exclusive: true
        enabled: !SettingsService.barConvexMode
        anchors.fill: parent

        sourceComponent: Component {
            MusicPopup {
                x: Math.round((root.width - implicitWidth) / 2)
                y: root.popupStartY
            }

        }

    }

    PopupLoader {
        id: dashboardLoader

        popupId: "dashboard"
        exclusive: true
        anchors.fill: parent

        sourceComponent: Component {
            Dashboard {
                anchors.fill: parent
                popupStartY: root.popupStartY
            }

        }

    }

    Repeater {
        model: QSSysTray.SystemTray.items

        SystemTray {
            popupId: "systemTray_" + index
            currentTrayItem: modelData
            positionAtRight: true
            x: {
                if (root.activeBarStyle === "minflair")
                    return root.width - implicitWidth - 8;

                if (root.activeBarStyle === "convex")
                    return root.width - implicitWidth - 16;

                if (root.isCompact) {
                    let notchOffset = root.activeBarStyle === "notch" ? 16 : 0;
                    return Math.min(root.width - implicitWidth - 8, Math.max(8, root.barStripX + root.barStripCenterX + root.barStripCenterWidth - implicitWidth - notchOffset));
                }
                return root.width - implicitWidth - 8;
            }
            y: (root.activeBarStyle === "notch" || root.activeBarStyle === "convex") ? root.popupStartY + 8 : root.popupStartY
            onIsOpenChanged: {
                if (isOpen)
                    root.activeTrayPopup = this;
                else if (root.activeTrayPopup === this)
                    root.activeTrayPopup = null;
            }
        }

    }

    PopupLoader {
        id: controlCenterLoader

        popupId: "controlCenter"
        exclusive: true
        anchors.fill: parent

        sourceComponent: Component {
            ControlCenter {
                notificationService: root.notificationService
                anchors.fill: parent
            }

        }

    }

    NotificationOverlay {
        id: notificationOverlay

        z: 10
        notificationService: root.notificationService
        anchors.fill: parent
    }

}
