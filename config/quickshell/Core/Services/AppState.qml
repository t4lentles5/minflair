import QtQuick
import Quickshell
import qs.Core
import qs.Core.Services
pragma Singleton

Item {
    id: appState

    property string activePopup: ""
    property var activePopupsList: []
    readonly property bool hasAnyPopupOpen: activePopupsList.length > 0 || activePopup !== ""
    readonly property bool isFocusPopupOpen: isPopupOpen("launcher") || isPopupOpen("clipboard") || isPopupOpen("wallpaper") || isPopupOpen("powerMenu") || isPopupOpen("screenshot")
    property int pendingSettingsTab: -1
    property var launcherApps: []
    property bool socketsCleaned: false
    property real islandWidth: 180
    property real islandHeight: 36
    readonly property real islandRadius: islandHeight / 2
    property real barIslandWidth: 180
    property real barIslandHeight: 36
    readonly property real barIslandRadius: barIslandHeight / 2
    property bool isIslandOpen: false
    property real barNotchWidth: 220
    property real barNotchHeight: 40
    property bool isNotchOpen: false
    property bool isConvexOpen: false
    property real barConvexWidth: 220
    property real barConvexHeight: 36
    property real activeConvexWidth: barConvexWidth
    property real activeConvexHeight: barConvexHeight
    property bool lockConvexCenterHeight: false
    property bool hasActiveNotification: false
    property real activeNotificationWidth: 0
    property real activeNotificationHeight: 0
    readonly property var focusPopups: ["launcher", "clipboard", "wallpaper", "screenshot", "powerMenu"]
    readonly property var standaloneWindows: ["minflair_settings", "minflair_keybinds", "packagemanager"]

    signal togglePopup(string popupId)
    signal openPopup(string popupId)

    function isFocusPopup(id) {
        return focusPopups.indexOf(id) !== -1;
    }

    function isStandaloneWindow(id) {
        return standaloneWindows.indexOf(id) !== -1;
    }

    function isPopupOpen(id) {
        if (!id || isStandaloneWindow(id))
            return false;

        if (activePopup === id)
            return true;

        return activePopupsList.indexOf(id) !== -1;
    }

    function getSlot(popupId, barStyle) {
        if (isFocusPopup(popupId))
            return "focus";

        let s = barStyle || SettingsService.barStyle;
        if (s === "island" || s === "notch") {
            if (popupId === "dashboard" || popupId === "controlCenter" || popupId === "music")
                return "center";

            if (popupId.startsWith("systemTray_"))
                return "tray";

        } else if (s === "framed") {
            if (popupId === "dashboard" || popupId === "music")
                return "top";

            if (popupId === "controlCenter" || popupId.startsWith("systemTray_"))
                return "right";

        } else if (s === "minflair") {
            if (popupId === "dashboard" || popupId === "music")
                return "top";

            if (popupId === "controlCenter" || popupId.startsWith("systemTray_"))
                return "right";

        } else if (s === "convex") {
            if (popupId === "dashboard")
                return "left";

            if (popupId === "music")
                return "center";

            if (popupId === "controlCenter" || popupId.startsWith("systemTray_"))
                return "right";

        }
        return popupId;
    }

    function closePopup(popupId) {
        if (!popupId)
            return ;

        if (activePopup === popupId)
            activePopup = "";

        let idx = activePopupsList.indexOf(popupId);
        if (idx !== -1) {
            let next = activePopupsList.slice();
            next.splice(idx, 1);
            activePopupsList = next;
        }
    }

    function closeAllPopups() {
        activePopup = "";
        activePopupsList = [];
    }

    function openPopupInternal(popupId) {
        if (!popupId || isStandaloneWindow(popupId))
            return ;

        let slot = getSlot(popupId);
        // Rule 1: Focus widgets close each other, but do NOT close bar widgets
        if (slot === "focus") {
            let next = [];
            for (let i = 0; i < activePopupsList.length; i++) {
                let item = activePopupsList[i];
                if (isFocusPopup(item))
                    continue;

                next.push(item);
            }
            next.push(popupId);
            activePopupsList = next;
            activePopup = popupId;
            return ;
        }
        // Rule 2: Opening a bar widget closes widgets in the same slot, but keeps focus widgets open
        let next = [];
        for (let i = 0; i < activePopupsList.length; i++) {
            let item = activePopupsList[i];
            if (getSlot(item) === slot)
                continue;

            next.push(item);
        }
        if (next.indexOf(popupId) === -1)
            next.push(popupId);

        if (SettingsService.barIslandMode || SettingsService.barNotchMode) {
            activePopup = popupId;
        } else if (isFocusPopup(activePopup)) {
        } else if (next.length === 1)
            activePopup = popupId;
        else if (next.length === 0)
            activePopup = "";
        activePopupsList = next;
    }

    function togglePopupInternal(popupId) {
        if (!popupId) {
            closeAllPopups();
            return ;
        }
        if (isStandaloneWindow(popupId))
            return ;

        if (isPopupOpen(popupId))
            closePopup(popupId);
        else
            openPopupInternal(popupId);
    }

    function formatTime(seconds) {
        if (seconds <= 0)
            return "Calculating...";

        let hours = Math.floor(seconds / 3600);
        let mins = Math.floor((seconds % 3600) / 60);
        if (hours > 0)
            return hours + "h " + mins + "m";
        else
            return mins + "m";
    }

    onActivePopupChanged: {
        if (activePopup === "") {
            let next = [];
            for (let i = 0; i < activePopupsList.length; i++) {
                let item = activePopupsList[i];
                if (isFocusPopup(item) || SettingsService.barIslandMode || SettingsService.barNotchMode)
                    continue;

                next.push(item);
            }
            if (next.length !== activePopupsList.length)
                activePopupsList = next;

        } else {
            if (activePopupsList.indexOf(activePopup) === -1)
                openPopupInternal(activePopup);

        }
    }
    onTogglePopup: (popupId) => {
        togglePopupInternal(popupId);
    }
    onOpenPopup: (popupId) => {
        openPopupInternal(popupId);
    }
}
