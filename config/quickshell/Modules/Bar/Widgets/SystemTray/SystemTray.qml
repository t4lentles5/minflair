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

    property string popupId: ""
    property var currentTrayItem: null
    property bool isOpen: false
    property bool positionAtRight: true
    readonly property int overshootHeadroom: 20
    readonly property bool isMinflair: SettingsService.barMinflairMode
    readonly property bool _visible: contentLoader.item ? contentLoader.item._visible : false

    signal popupOpened()
    signal popupClosed()
    signal fullyClosed()

    implicitWidth: contentLoader.item ? contentLoader.item.implicitWidth : 0
    implicitHeight: contentLoader.item ? contentLoader.item.implicitHeight : 0
    visible: _visible
    onIsOpenChanged: {
        if (!root.isOpen) {
            AppState.closePopup(root.popupId);
            if (contentLoader.item && contentLoader.item.content && contentLoader.item.content.length > 0) {
                if (contentLoader.item.content[0].resetToRoot)
                    contentLoader.item.content[0].resetToRoot();

            }
        }
        if (contentLoader.item && contentLoader.item.isOpen !== root.isOpen)
            contentLoader.item.isOpen = root.isOpen;

    }

    Loader {
        id: contentLoader

        anchors.fill: parent
        sourceComponent: topPopupComponent
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

        function onPopupOpened() {
            root.popupOpened();
        }

        function onPopupClosed() {
            root.popupClosed();
        }

        function onFullyClosed() {
            root.fullyClosed();
            AppState.closePopup(root.popupId);
        }

        target: contentLoader.item
        ignoreUnknownSignals: true
    }

    Connections {
        function onTogglePopup(id) {
            if (id === root.popupId)
                root.isOpen = !root.isOpen;
            else if (root.isOpen && id !== "" && AppState.getSlot(id) === AppState.getSlot(root.popupId))
                root.isOpen = false;
        }

        function onOpenPopup(id) {
            if (id === root.popupId)
                root.isOpen = true;
            else if (root.isOpen && id !== "" && AppState.getSlot(id) === AppState.getSlot(root.popupId))
                root.isOpen = false;
        }

        enabled: root.enabled
        target: AppState
    }

    Component {
        id: topPopupComponent

        TopPopup {
            popupId: root.popupId
            positionAtRight: root.isMinflair ? false : root.positionAtRight
            animateHeight: root.isMinflair
            contentPadding: root.isMinflair ? Constants.sizeLg : 16
            backgroundColor: Theme.bg
            contentWidth: Math.max(250, Math.min(trayMenuTop.implicitWidth, 450))
            contentHeight: Math.min(trayMenuTop.implicitHeight, 420)

            TrayMenu {
                id: trayMenuTop

                anchors.fill: parent
                menuHandle: root.currentTrayItem ? root.currentTrayItem.menu : null
                title: {
                    let item = root.currentTrayItem;
                    if (!item)
                        return "Menu";

                    let t = item.title ? item.title.toString().trim() : "";
                    if (t !== "")
                        return t;

                    let tt = item.toolTipTitle ? item.toolTipTitle.toString().trim() : "";
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
                onBackRequested: root.isOpen = false
                onCloseRequested: root.isOpen = false
            }

        }

    }

}
