import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import qs.Core
import qs.Core.Services
pragma Singleton

Item {
    id: appState

    property string activeWidget: ""
    property var activeWidgetsList: []
    readonly property bool isFocusWidgetOpen: isWidgetOpen("launcher") || isWidgetOpen("clipboard") || isWidgetOpen("wallpaper") || isWidgetOpen("powerMenu") || isWidgetOpen("screenshot")
    property int pendingSettingsTab: -1
    property var launcherApps: []
    property bool socketsCleaned: true
    property real islandWidth: 180
    property real islandHeight: Constants.islandBarHeight
    property alias barIslandWidth: appState.islandWidth
    property alias barIslandHeight: appState.islandHeight
    property bool isIslandOpen: false
    property bool islandClosing: false
    property bool isConvexOpen: false
    property real barConvexWidth: 220
    property real barConvexHeight: Constants.size4Xl
    property var activeTrayItem: null
    property bool activeTrayItemPinned: false
    readonly property var trayItems: SystemTray.items
    property bool hasActiveNotification: false
    property real activeNotificationWidth: 0
    property real activeNotificationHeight: 0
    readonly property var focusWidgets: ["launcher", "clipboard", "wallpaper", "screenshot", "powerMenu"]
    readonly property var standaloneWindows: ["minflair_settings", "minflair_keybinds", "packagemanager", "pomodoro"]
    readonly property int activeTrayIndex: {
        if (!activeWidget || !activeWidget.startsWith("systemTray_"))
            return -1;

        const idx = parseInt(activeWidget.split("_")[1]);
        return isNaN(idx) ? -1 : idx;
    }
    readonly property var resolvedTrayItem: {
        if (isTrayItemPresent(activeTrayItem))
            return activeTrayItem;

        // The pinned item was destroyed (its application quit). Do not fall
        // back to the index: it now points at a different tray item.
        if (activeTrayItemPinned)
            return null;

        return trayItemAt(activeTrayIndex);
    }

    signal toggleWidget(string widgetId)
    signal openWidget(string widgetId)

    function isBarWidget(id) {
        if (!id)
            return false;

        return id === "dashboard" || id === "controlCenter" || id === "notificationsCenter" || id === "music" || id === "calendar" || id === "systemUsage" || id.startsWith("systemTray_");
    }

    function isFocusWidget(id) {
        return focusWidgets.indexOf(id) !== -1;
    }

    function isBarOverlayWidget(id) {
        return isFocusWidget(id) || isBarWidget(id);
    }

    function isStandaloneWindow(id) {
        return standaloneWindows.indexOf(id) !== -1;
    }

    function trayItemAt(index) {
        if (index < 0)
            return null;

        const items = SystemTray.items;
        if (!items)
            return null;

        if (items.values && index < items.values.length)
            return items.values[index];

        if (index < items.length)
            return items[index];

        return null;
    }

    function isTrayItemValid(item) {
        if (!item)
            return false;

        try {
            return item.id !== undefined;
        } catch (e) {
            return false;
        }
    }

    function isTrayItemPresent(item) {
        if (!isTrayItemValid(item))
            return false;

        const items = SystemTray.items;
        if (!items)
            return false;

        const list = items.values ? items.values : items;
        for (let i = 0; i < list.length; i++) {
            if (list[i] === item)
                return true;

        }
        return false;
    }

    function validateTrayWidgets() {
        let ids = [];
        for (let i = 0; i < activeWidgetsList.length; i++) {
            const id = activeWidgetsList[i];
            if (id && id.startsWith("systemTray_"))
                ids.push(id);

        }
        if (activeWidget && activeWidget.startsWith("systemTray_") && ids.indexOf(activeWidget) === -1)
            ids.push(activeWidget);

        if (ids.length === 0) {
            // Drop a stale pin left by an item that died while its menu was
            // already closed (e.g. another widget replaced it).
            if (activeTrayItemPinned && !isTrayItemPresent(activeTrayItem))
                activeTrayItemPinned = false;

            return ;
        }
        if (activeTrayItemPinned) {
            if (!isTrayItemPresent(activeTrayItem)) {
                for (let i = 0; i < ids.length; i++) closeWidget(ids[i])
            }
            return ;
        }
        for (let i = 0; i < ids.length; i++) {
            const idx = parseInt(ids[i].split("_")[1]);
            if (isNaN(idx) || !trayItemAt(idx))
                closeWidget(ids[i]);

        }
    }

    function trayTitle(item) {
        if (!item)
            return "Menu";

        const title = item.title ? item.title.toString().trim() : "";
        if (title !== "")
            return title;

        const tooltip = item.tooltipTitle ? item.tooltipTitle.toString().trim() : (item.toolTipTitle ? item.toolTipTitle.toString().trim() : "");
        if (tooltip !== "")
            return tooltip;

        const id = item.id ? item.id.toString().trim() : "";
        if (id !== "" && !id.startsWith("org.kde.StatusNotifier")) {
            const clean = id.replace(/_status_icon_\d+$/i, "").replace(/[-_]/g, " ");
            return clean.charAt(0).toUpperCase() + clean.slice(1);
        }
        return "Menu";
    }

    function isWidgetOpen(id) {
        if (!id || isStandaloneWindow(id))
            return false;

        if (activeWidget === id)
            return true;

        return activeWidgetsList.indexOf(id) !== -1;
    }

    function getSlot(widgetId, barStyle) {
        if (isFocusWidget(widgetId))
            return "focus";

        let s = barStyle || SettingsService.barStyle;
        if (s === "island")
            return "center";

        // convex
        if (widgetId === "dashboard")
            return "left";

        if (widgetId === "music" || widgetId === "calendar" || widgetId === "systemUsage")
            return "center";

        if (widgetId === "controlCenter" || widgetId === "notificationsCenter" || widgetId.startsWith("systemTray_"))
            return "right";

        return widgetId;
    }

    function closeWidget(widgetId) {
        if (!widgetId)
            return ;

        if (widgetId.startsWith("systemTray_") || activeWidget === widgetId) {
            activeTrayItem = null;
            activeTrayItemPinned = false;
        }
        let idx = activeWidgetsList.indexOf(widgetId);
        if (idx !== -1) {
            let next = activeWidgetsList.slice();
            next.splice(idx, 1);
            activeWidgetsList = next;
        }
        if (activeWidget === widgetId)
            activeWidget = "";

    }

    function closeAllWidgets() {
        activeTrayItem = null;
        activeTrayItemPinned = false;
        activeWidgetsList = [];
        activeWidget = "";
    }

    function openWidgetInternal(widgetId) {
        if (!widgetId || isStandaloneWindow(widgetId))
            return ;

        // Opening a tray widget by index (IPC/keybind) has no item reference
        // yet. Pin the current item so closing its application also closes
        // the menu instead of showing whichever item takes over the index.
        if (widgetId.startsWith("systemTray_") && !isTrayItemValid(activeTrayItem)) {
            const index = parseInt(widgetId.split("_")[1]);
            const item = isNaN(index) ? null : trayItemAt(index);
            if (item)
                activeTrayItem = item;

        }
        let slot = getSlot(widgetId);
        // Rule 1: Focus widgets close each other, but do NOT close bar widgets
        if (slot === "focus") {
            let next = [];
            for (let i = 0; i < activeWidgetsList.length; i++) {
                let item = activeWidgetsList[i];
                if (isFocusWidget(item))
                    continue;

                next.push(item);
            }
            next.push(widgetId);
            activeWidgetsList = next;
            activeWidget = widgetId;
            return ;
        }
        // Rule 2: Opening a bar widget closes widgets in the same slot, but keeps focus widgets open
        let next = [];
        for (let i = 0; i < activeWidgetsList.length; i++) {
            let item = activeWidgetsList[i];
            if (getSlot(item) === slot)
                continue;

            next.push(item);
        }
        if (next.indexOf(widgetId) === -1)
            next.push(widgetId);

        activeWidgetsList = next;
        activeWidget = widgetId;
    }

    function toggleWidgetInternal(widgetId) {
        if (!widgetId) {
            closeAllWidgets();
            return ;
        }
        if (isStandaloneWindow(widgetId))
            return ;

        if (isWidgetOpen(widgetId))
            closeWidget(widgetId);
        else
            openWidgetInternal(widgetId);
    }

    onActiveTrayItemChanged: {
        if (isTrayItemValid(activeTrayItem))
            activeTrayItemPinned = true;

    }
    onActiveWidgetChanged: {
        if (activeWidget === "") {
            let next = [];
            for (let i = 0; i < activeWidgetsList.length; i++) {
                let item = activeWidgetsList[i];
                if (isFocusWidget(item))
                    next.push(item);

            }
            if (next.length !== activeWidgetsList.length)
                activeWidgetsList = next;

        } else {
            if (activeWidgetsList.indexOf(activeWidget) === -1)
                openWidgetInternal(activeWidget);

        }
    }
    onToggleWidget: (widgetId) => {
        toggleWidgetInternal(widgetId);
    }
    onOpenWidget: (widgetId) => {
        openWidgetInternal(widgetId);
    }

    Connections {
        function onValuesChanged() {
            appState.validateTrayWidgets();
        }

        target: appState.trayItems
    }

}
