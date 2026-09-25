pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs.Core
import qs.Core.Services

QtObject {
    id: root

    property Notification notification
    property string notificationId
    property string summary: ""
    property string body: ""
    property string appName: "System"
    property string appIcon: ""
    property string image: ""

    property int urgency: NotificationUrgency.Normal
    property double timestamp: new Date().getTime()
    property bool popup: true
    property bool isDnd: false
    property bool closed: false
    
    property bool isTransient: summary === "Volume" || summary === "Brightness" || summary === "Microphone" || summary === "Power Menu" || body.includes("Taking shot in")
    
    property real progress: 1.0 

    property var locks: []

    readonly property bool isObscured: {
        let isNotchHostPopup = AppState.isPopupOpen("dashboard") || AppState.isPopupOpen("controlCenter") || AppState.isPopupOpen("music");
        let isIslandHostPopup = isNotchHostPopup || AppState.isPopupOpen("launcher") || AppState.isPopupOpen("clipboard") || AppState.isPopupOpen("wallpaper");
        if (SettingsService.barNotchMode)
            return isNotchHostPopup || AppState.isNotchOpen;
        if (SettingsService.barIslandMode)
            return isIslandHostPopup || AppState.isIslandOpen;
        if (SettingsService.barConvexMode)
            return AppState.isPopupOpen("music") || AppState.isConvexOpen;
        return false;
    }

    onIsObscuredChanged: {
        if (!isObscured) {
            startProgress();
        } else {
            if (progressAnim.running) {
                progressAnim.stop();
                progress = 1.0;
            }
        }
    }

    property NumberAnimation progressAnim: NumberAnimation {
        target: root
        property: "progress"
        from: 1.0
        to: 0.0
        duration: {
            if (root.summary === "Power Menu") return 10000;
            if (root.summary === "Volume" || root.summary === "Brightness" || root.summary === "Microphone") return 1500;
            return 5000;
        }
        onFinished: {
            root.popup = false;
        }
    }

    function startProgress() {
        if (popup && (!isDnd || urgency === 2) && !closed && urgency !== 2 && !isObscured && locks.length === 0) {
            progress = 1.0;
            progressAnim.restart();
        }
    }

    readonly property Connections conn: Connections {
        function onClosed() {
            root.close();
        }

        function onSummaryChanged() {
            root.summary = root.notification.summary;
            root.startProgress();
        }

        function onBodyChanged() {
            root.body = root.notification.body;
            root.startProgress();
        }

        function onAppIconChanged() {
            root.appIcon = root.notification.appIcon;
        }

        function onAppNameChanged() {
            root.appName = root.notification.appName;
        }

        function onImageChanged() {
            root.image = root.notification.image;
        }

        function onUrgencyChanged() {
            root.urgency = root.notification.urgency;
            root.startProgress();
        }

        target: root.notification
    }

    function lock(item) {
        if (!locks.includes(item)) {
            locks.push(item);
        }
        if (progressAnim.running) {
            progressAnim.pause();
        }
    }

    function unlock(item) {
        let idx = locks.indexOf(item);
        if (idx !== -1) {
            locks.splice(idx, 1);
        }
        if (locks.length === 0 && popup && !root.closed && urgency !== 2 && !isObscured) {
            if (progressAnim.paused)
                progressAnim.resume();
            else if (!progressAnim.running && progress > 0)
                progressAnim.restart();
        }
    }

    function close() {
        if (closed) return;
        closed = true;
        popup = false;
        progressAnim.stop();
        notification?.dismiss();
    }

    Component.onCompleted: {
        if (notification) {
            notificationId = notification.id;
            summary = notification.summary;
            body = notification.body;
            appIcon = notification.appIcon;
            appName = notification.appName;
            image = notification.image;
            urgency = notification.urgency;
        }
        startProgress();
    }
}
