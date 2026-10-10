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
    property real progress: 1
    property var locks: ({
    })
    readonly property bool isLocked: Object.keys(locks).length > 0
    readonly property bool isObscured: {
        let isIslandHostPopup = AppState.isWidgetOpen("dashboard") || AppState.isWidgetOpen("controlCenter") || AppState.isWidgetOpen("music") || AppState.isWidgetOpen("launcher") || AppState.isWidgetOpen("clipboard") || AppState.isWidgetOpen("wallpaper");
        if (SettingsService.barIslandMode)
            return isIslandHostPopup || AppState.isIslandOpen;

        if (SettingsService.barConvexMode)
            return AppState.isWidgetOpen("music") || AppState.isConvexOpen;

        return false;
    }
    property NumberAnimation progressAnim

    progressAnim: NumberAnimation {
        target: root
        property: "progress"
        from: 1
        to: 0
        duration: {
            if (root.summary === "Power Menu")
                return 10000;

            if (root.summary === "Volume" || root.summary === "Brightness" || root.summary === "Microphone")
                return 1500;

            return 5000;
        }
        onFinished: {
            if (!root.isLocked)
                root.popup = false;

        }
    }

    readonly property Connections
    conn: Connections {
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

    function startProgress() {
        if (popup && (!isDnd || urgency === 2) && !closed && urgency !== 2 && !isObscured && !isLocked) {
            progress = 1;
            progressAnim.restart();
        }
    }

    function lock(item) {
        let key = typeof item === "string" ? item : "default";
        let newLocks = Object.assign({
        }, locks);
        newLocks[key] = true;
        locks = newLocks;
        if (progressAnim.running)
            progressAnim.pause();

    }

    function unlock(item) {
        let key = typeof item === "string" ? item : "default";
        let newLocks = Object.assign({
        }, locks);
        delete newLocks[key];
        locks = newLocks;
        if (Object.keys(newLocks).length === 0 && popup && !root.closed && urgency !== 2 && !isObscured) {
            if (progressAnim.paused)
                progressAnim.resume();
            else if (!progressAnim.running && progress > 0)
                progressAnim.restart();
        }
    }

    function close() {
        if (closed)
            return ;

        closed = true;
        popup = false;
        locks = ({
        });
        progressAnim.stop();
        if (notification)
            notification.dismiss();

    }

    onIsObscuredChanged: {
        if (!isObscured) {
            startProgress();
        } else {
            if (progressAnim.running) {
                progressAnim.stop();
                progress = 1;
            }
        }
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
