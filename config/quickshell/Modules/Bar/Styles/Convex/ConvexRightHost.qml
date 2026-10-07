import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray as QSSysTray
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Core.Windows
import qs.Modules.Bar.Widgets.SystemTray
import qs.Modules.ControlCenter
import qs.Modules.NotificationCenter

Item {
    id: root

    property var notificationService: null
    readonly property bool isControlCenter: AppState.isWidgetOpen("controlCenter")
    readonly property bool isNotificationsCenter: AppState.isWidgetOpen("notificationsCenter")
    readonly property bool isTray: (AppState.activeWidget || "").startsWith("systemTray_") || (activeWidgetId || "").startsWith("systemTray_")
    readonly property int activeTrayIndex: {
        let targetId = AppState.activeWidget && AppState.activeWidget.startsWith("systemTray_") ? AppState.activeWidget : activeWidgetId;
        if (targetId && targetId.startsWith("systemTray_")) {
            let parts = targetId.split("_");
            if (parts.length > 1) {
                let idx = parseInt(parts[1]);
                if (!isNaN(idx))
                    return idx;

            }
        }
        return -1;
    }
    readonly property var activeTrayItem: {
        if (!isTray)
            return null;

        if (AppState.activeTrayItem)
            return AppState.activeTrayItem;

        return getTrayItem(activeTrayIndex);
    }
    readonly property string activeTrayTitle: {
        let item = activeTrayItem;
        if (!item)
            return "Menu";

        let t = item.title ? item.title.toString().trim() : "";
        if (t !== "")
            return t;

        let tt = item.tooltipTitle ? item.tooltipTitle.toString().trim() : (item.toolTipTitle ? item.toolTipTitle.toString().trim() : "");
        if (tt !== "")
            return tt;

        let id = item.id ? item.id.toString().trim() : "";
        if (id !== "" && !id.startsWith("org.kde.StatusNotifier")) {
            let clean = id.replace(/_status_icon_\d+$/i, "").replace(/[-_]/g, " ");
            return clean.charAt(0).toUpperCase() + clean.slice(1);
        }
        return "Menu";
    }
    readonly property string activeWidgetId: {
        if (AppState.activeWidget === "controlCenter")
            return "controlCenter";

        if (AppState.activeWidget === "notificationsCenter")
            return "notificationsCenter";

        if (AppState.activeWidget && AppState.activeWidget.startsWith("systemTray_"))
            return AppState.activeWidget;

        if (isControlCenter)
            return "controlCenter";

        if (isNotificationsCenter)
            return "notificationsCenter";

        for (let i = 0; i < AppState.activeWidgetsList.length; i++) {
            let item = AppState.activeWidgetsList[i];
            if (item && item.startsWith("systemTray_"))
                return item;

        }
        return "";
    }
    readonly property bool isOpen: activeWidgetId !== ""
    property string displayedWidgetId: "controlCenter"
    readonly property bool _visible: sidebarWindow._visible
    property alias controlCenterWidget: ccFacade
    property alias notificationsCenterWidget: ncFacade
    readonly property var activeTrayMenu: isTray ? sidebarWindow : null
    property real contentCrossFade: 1

    function getTrayCount() {
        let items = QSSysTray.SystemTray.items;
        if (!items)
            return 0;

        if (items.values)
            return items.values.length;

        if (items.length !== undefined)
            return items.length;

        if (items.count !== undefined)
            return items.count;

        return 0;
    }

    function getTrayItem(idx) {
        if (idx < 0)
            return null;

        let items = QSSysTray.SystemTray.items;
        if (!items)
            return null;

        if (items.values && idx < items.values.length)
            return items.values[idx];

        if (idx < items.length)
            return items[idx];

        return null;
    }

    onActiveWidgetIdChanged: {
        if (activeWidgetId !== "") {
            if (isOpen && displayedWidgetId !== "" && displayedWidgetId !== activeWidgetId) {
                contentCrossFade = 0;
                displayedWidgetId = activeWidgetId;
                contentFadeTimer.restart();
            } else {
                displayedWidgetId = activeWidgetId;
                contentCrossFade = 1;
            }
        }
    }
    anchors.fill: parent

    // Resilient facades with Connections so external JS reads to .isOpen remain reactive
    QtObject {
        id: ccFacade

        property bool isOpen: AppState.isWidgetOpen("controlCenter")
    }

    QtObject {
        id: ncFacade

        property bool isOpen: AppState.isWidgetOpen("notificationsCenter")
    }

    Connections {
        function onActiveWidgetChanged() {
            ccFacade.isOpen = AppState.isWidgetOpen("controlCenter");
            ncFacade.isOpen = AppState.isWidgetOpen("notificationsCenter");
        }

        function onActiveWidgetsListChanged() {
            ccFacade.isOpen = AppState.isWidgetOpen("controlCenter");
            ncFacade.isOpen = AppState.isWidgetOpen("notificationsCenter");
        }

        function onToggleWidget() {
            Qt.callLater(() => {
                ccFacade.isOpen = AppState.isWidgetOpen("controlCenter");
                ncFacade.isOpen = AppState.isWidgetOpen("notificationsCenter");
            });
        }

        function onOpenWidget() {
            Qt.callLater(() => {
                ccFacade.isOpen = AppState.isWidgetOpen("controlCenter");
                ncFacade.isOpen = AppState.isWidgetOpen("notificationsCenter");
            });
        }

        target: AppState
    }

    Timer {
        id: contentFadeTimer

        interval: 40
        repeat: false
        onTriggered: {
            root.contentCrossFade = 1;
        }
    }

    Binding {
        target: sidebarWindow
        property: "isOpen"
        value: root.isOpen
    }

    SidebarWindow {
        id: sidebarWindow

        anchors.fill: parent
        widgetId: root.activeWidgetId !== "" ? root.activeWidgetId : root.displayedWidgetId
        positionAtLeft: false
        backgroundColor: Theme.bg
        alignTop: root.displayedWidgetId.startsWith("systemTray_")
        topOffset: SettingsService.barConvexMode ? 80 : Constants.size4Xl
        preferredWidth: 0
        preferredHeight: 0
        // Exact original dimensions per widget
        contentWidth: {
            if (root.displayedWidgetId === "controlCenter")
                return ccContent.implicitWidth > 0 ? ccContent.implicitWidth : 500;

            if (root.displayedWidgetId === "notificationsCenter")
                return ncContent.implicitWidth > 0 ? ncContent.implicitWidth : 400;

            if (root.displayedWidgetId.startsWith("systemTray_"))
                return 300;

            return 500;
        }
        contentHeight: {
            if (root.displayedWidgetId === "controlCenter")
                return ccContent.implicitHeight > 0 ? ccContent.implicitHeight : 600;

            if (root.displayedWidgetId === "notificationsCenter")
                return ncContent.implicitHeight > 0 ? ncContent.implicitHeight : 450;

            if (root.displayedWidgetId.startsWith("systemTray_"))
                return 340;

            return 600;
        }
        onFullyClosed: {
            if (!root.isOpen) {
                root.displayedWidgetId = "controlCenter";
                if (trayContent && typeof trayContent.resetToRoot === "function")
                    trayContent.resetToRoot();

            }
        }

        StackLayout {
            id: rightStack

            Layout.fillWidth: true
            Layout.fillHeight: true
            opacity: root.contentCrossFade
            currentIndex: {
                if (root.displayedWidgetId === "controlCenter")
                    return 0;

                if (root.displayedWidgetId === "notificationsCenter")
                    return 1;

                if (root.displayedWidgetId.startsWith("systemTray_"))
                    return 2;

                return 0;
            }

            // Layer 0: Control Center (exact original content)
            ControlCenterContent {
                id: ccContent

                Layout.fillWidth: true
                Layout.fillHeight: true
                widget: sidebarWindow
                notificationService: root.notificationService
            }

            // Layer 1: Notification Center (exact original content)
            NotificationCenter {
                id: ncContent

                Layout.fillWidth: true
                Layout.fillHeight: true
                controlCenterOpen: root.displayedWidgetId === "notificationsCenter"
                notificationService: root.notificationService
            }

            // Layer 2: System Tray Menu (exact original content)
            TrayMenu {
                id: trayContent

                Layout.fillWidth: true
                Layout.fillHeight: true
                menuHandle: (root.isTray && root.activeTrayItem) ? root.activeTrayItem.menu : null
                title: root.activeTrayTitle
                onBackRequested: {
                    if (root.activeWidgetId !== "")
                        AppState.closeWidget(root.activeWidgetId);

                }
                onCloseRequested: {
                    if (root.activeWidgetId !== "")
                        AppState.closeWidget(root.activeWidgetId);

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

}
