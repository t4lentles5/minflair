import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Core.Windows

Item {
    id: root

    property string widgetId: ""
    property var currentTrayItem: null
    property bool isOpen: false
    property bool positionAtRight: true
    readonly property int overshootHeadroom: Constants.size2Xl
    readonly property bool _visible: contentLoader.item ? contentLoader.item._visible : false

    signal widgetOpened()
    signal widgetClosed()
    signal fullyClosed()

    implicitWidth: contentLoader.item ? contentLoader.item.implicitWidth : 0
    implicitHeight: contentLoader.item ? contentLoader.item.implicitHeight : 0
    visible: _visible
    onIsOpenChanged: {
        if (contentLoader.item && contentLoader.item.isOpen !== root.isOpen)
            contentLoader.item.isOpen = root.isOpen;

    }

    Loader {
        id: contentLoader

        anchors.fill: parent
        sourceComponent: sidebarComponent
        onStatusChanged: {
            if (status === Loader.Ready && item)
                item.isOpen = root.isOpen;

        }
    }

    Connections {
        function onIsOpenChanged() {
            if (contentLoader.item && root.isOpen !== contentLoader.item.isOpen)
                root.isOpen = contentLoader.item.isOpen;

        }

        function onWidgetOpened() {
            root.widgetOpened();
        }

        function onWidgetClosed() {
            root.widgetClosed();
        }

        function onFullyClosed() {
            if (contentLoader.item && contentLoader.item.content && contentLoader.item.content.length > 0) {
                if (contentLoader.item.content[0].resetToRoot)
                    contentLoader.item.content[0].resetToRoot();

            }
            root.fullyClosed();
            AppState.closeWidget(root.widgetId);
        }

        target: contentLoader.item
        ignoreUnknownSignals: true
    }

    Component {
        id: sidebarComponent

        SidebarWindow {
            widgetId: root.widgetId
            isOpen: root.isOpen
            alignTop: true
            topOffset: SettingsService.barConvexMode ? 80 : Constants.size4Xl
            positionAtLeft: false
            backgroundColor: Theme.bg
            contentWidth: 300
            contentHeight: 340

            TrayMenu {
                id: trayMenuTop

                Layout.fillWidth: true
                Layout.fillHeight: true
                menuHandle: root.currentTrayItem ? root.currentTrayItem.menu : null
                title: {
                    let item = root.currentTrayItem;
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
                        let clean = id.replace(/_status_icon_\d+$/i, "");
                        clean = clean.replace(/[-_]/g, " ");
                        clean = clean.split(" ").map((w) => {
                            return w.charAt(0).toUpperCase() + w.slice(1);
                        }).join(" ");
                        return clean.trim();
                    }
                    return "Menu";
                }
                onBackRequested: AppState.closeWidget(root.widgetId)
                onCloseRequested: AppState.closeWidget(root.widgetId)
            }

        }

    }

    Binding on isOpen {
        value: AppState.isWidgetOpen(root.widgetId)
    }

}
