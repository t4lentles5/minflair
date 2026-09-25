import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs.Core
import qs.Core.Services

Item {
    id: root

    property alias server: notificationServer
    property alias activeList: activeListModel
    property alias historyList: historyListModel
    property bool dndEnabled: false
    property int unreadCount: historyListModel.count
    property var notificationObjects: ({
    })
    property var notificationGroups: ({
    })
    property var groupRepresentationIds: ({
    })

    function pruneForIslandMode() {
        if (SettingsService.barIslandMode || SettingsService.barNotchMode) {
            while (activeListModel.count > 1) {
                let oldItem = activeListModel.get(1);
                if (oldItem && oldItem.notifData)
                    oldItem.notifData.popup = false;

                activeListModel.remove(1);
            }
        }
    }

    function notify(summary, body, icon = "", appName = "System", urgency = NotificationUrgency.Normal) {
        let timestamp = new Date().getTime();
        let nd = notificationDataComponent.createObject(root, {
            "notificationId": timestamp.toString(),
            "summary": summary,
            "body": body,
            "appName": appName,
            "appIcon": icon,
            "urgency": urgency,
            "timestamp": timestamp,
            "isDnd": root.dndEnabled
        });
        notificationObjects[timestamp] = nd;
        historyListModel.insert(0, {
            "id": timestamp,
            "notifData": nd
        });
        if (!dndEnabled) {
            activeListModel.insert(0, {
                "id": timestamp,
                "notifData": nd
            });
            pruneForIslandMode();
        }
    }

    function dismissNotification(id) {
        let nd = notificationObjects[id];
        if (nd)
            nd.close();

        removeNotification(id);
    }

    function getGroupKey(notification) {
        let appsToGroup = ["whatsapp", "telegram", "discord", "slack"];
        let app = (notification.appName || "").toLowerCase();
        for (let i = 0; i < appsToGroup.length; i++) {
            if (app.includes(appsToGroup[i]))
                return appsToGroup[i];

        }
        return "";
    }

    function copyObject(obj) {
        let copy = {
        };
        for (let k in obj) {
            copy[k] = obj[k];
        }
        return copy;
    }

    function removeNotification(id) {
        for (let groupKey in groupRepresentationIds) {
            if (groupRepresentationIds[groupKey] == id) {
                let groups = copyObject(notificationGroups);
                groups[groupKey] = [];
                notificationGroups = groups;
                let reps = copyObject(groupRepresentationIds);
                delete reps[groupKey];
                groupRepresentationIds = reps;
                break;
            }
        }
        if (notificationObjects[id]) {
            notificationObjects[id].destroy(1000);
            delete notificationObjects[id];
        }
        for (var i = 0; i < activeListModel.count; i++) {
            if (activeListModel.get(i).id == id) {
                activeListModel.remove(i);
                break;
            }
        }
        for (var j = 0; j < historyListModel.count; j++) {
            if (historyListModel.get(j).id == id) {
                historyListModel.remove(j);
                break;
            }
        }
    }

    function clearHistory() {
        notificationGroups = {
        };
        groupRepresentationIds = {
        };
        for (let id in notificationObjects) {
            notificationObjects[id].destroy();
        }
        notificationObjects = {
        };
        historyListModel.clear();
        activeListModel.clear();
    }

    function removeHistoryItem(index) {
        if (index >= 0 && index < historyListModel.count) {
            let id = historyListModel.get(index).id;
            removeNotification(id);
        }
    }

    function handleNotificationUpdate(notification) {
        let groupKey = getGroupKey(notification);
        if (!groupKey) {
            root.updateNotificationData(notification);
            return ;
        }
        let groups = copyObject(notificationGroups);
        if (!groups[groupKey])
            groups[groupKey] = [];

        let msgIndex = -1;
        for (let i = 0; i < groups[groupKey].length; i++) {
            if (groups[groupKey][i].id == notification.id) {
                msgIndex = i;
                break;
            }
        }
        let msgData = {
            "id": notification.id,
            "summary": notification.summary ? notification.summary : "",
            "body": notification.body ? notification.body : "",
            "timestamp": new Date().getTime()
        };
        if (msgIndex >= 0)
            groups[groupKey][msgIndex] = msgData;
        else
            groups[groupKey].push(msgData);
        notificationGroups = groups;
        let reps = copyObject(groupRepresentationIds);
        let repId = reps[groupKey];
        if (!repId || repId == notification.id) {
            reps[groupKey] = notification.id;
            groupRepresentationIds = reps;
            root.updateNotificationData(notification);
        } else {
            if (!notification.alreadyDismissed) {
                notification.alreadyDismissed = true;
                notification.dismiss();
            }
            let repData = notificationObjects[repId];
            if (repData) {
                let displayNames = {
                    "whatsapp": "WhatsApp",
                    "telegram": "Telegram",
                    "discord": "Discord",
                    "slack": "Slack"
                };
                let displayName = displayNames[groupKey] || repData.appName;
                let combinedBody = groups[groupKey].map((m) => {
                    return (m.summary ? m.summary + ": " : "") + m.body;
                }).join("\n");
                let combinedSummary = displayName + " (" + groups[groupKey].length + ")";
                repData.summary = combinedSummary;
                repData.body = combinedBody;
                repData.appName = displayName;
                repData.timestamp = new Date().getTime();
                let historyIndex = -1;
                for (let i = 0; i < historyListModel.count; i++) {
                    if (historyListModel.get(i).id == repId) {
                        historyIndex = i;
                        break;
                    }
                }
                if (historyIndex > 0)
                    historyListModel.move(historyIndex, 0, 1);

                if (!dndEnabled) {
                    let activeIndex = -1;
                    for (let i = 0; i < activeListModel.count; i++) {
                        if (activeListModel.get(i).id == repId) {
                            activeIndex = i;
                            break;
                        }
                    }
                    repData.popup = true;
                    repData.startProgress();
                    if (activeIndex > 0)
                        activeListModel.move(activeIndex, 0, 1);
                    else if (activeIndex === -1)
                        activeListModel.insert(0, {
                        "id": repId,
                        "notifData": repData
                    });
                    pruneForIslandMode();
                }
            }
        }
    }

    function updateNotificationData(notification) {
        let nd = notificationObjects[notification.id];
        if (!nd) {
            nd = notificationDataComponent.createObject(root, {
                "notification": notification,
                "isDnd": root.dndEnabled
            });
            notificationObjects[notification.id] = nd;
        } else {
            if (nd.notification !== notification) {
                nd.notification = notification;
                nd.summary = notification.summary;
                nd.body = notification.body;
                nd.appIcon = notification.appIcon;
                nd.appName = notification.appName;
                nd.image = notification.image;
                nd.urgency = notification.urgency;
            }
            if ((!nd.isDnd || nd.urgency === 2) && !nd.closed) {
                nd.popup = true;
                nd.startProgress();
            }
        }
        if (!nd.isTransient) {
            let historyUpdated = false;
            for (let i = 0; i < historyListModel.count; i++) {
                if (historyListModel.get(i).id == notification.id) {
                    if (i > 0)
                        historyListModel.move(i, 0, 1);

                    historyUpdated = true;
                    break;
                }
            }
            if (!historyUpdated)
                historyListModel.insert(0, {
                "id": notification.id,
                "notifData": nd
            });

        }
        if ((!dndEnabled || nd.urgency === 2) && nd.popup) {
            let activeUpdated = false;
            for (let i = 0; i < activeListModel.count; i++) {
                if (activeListModel.get(i).id == notification.id) {
                    if (i > 0)
                        activeListModel.move(i, 0, 1);

                    activeUpdated = true;
                    break;
                }
            }
            if (!activeUpdated)
                activeListModel.insert(0, {
                "id": notification.id,
                "notifData": nd
            });

            pruneForIslandMode();
        }
        while (historyListModel.count > 50)removeHistoryItem(historyListModel.count - 1)
    }

    onDndEnabledChanged: {
        for (let id in notificationObjects) {
            notificationObjects[id].isDnd = root.dndEnabled;
            if (root.dndEnabled && notificationObjects[id].urgency !== 2)
                notificationObjects[id].popup = false;

        }
        if (root.dndEnabled) {
            for (let i = activeListModel.count - 1; i >= 0; i--) {
                if (activeListModel.get(i).notifData.urgency !== 2)
                    activeListModel.remove(i);

            }
        }
    }

    Component {
        id: notificationDataComponent

        NotificationData {
        }

    }

    Connections {
        function onGameModeActiveChanged() {
            if (DisplayProfileService.gameModeActive)
                root.dndEnabled = true;
            else
                root.dndEnabled = false;
        }

        target: DisplayProfileService
    }

    Connections {
        function onBarIslandModeChanged() {
            root.pruneForIslandMode();
        }

        target: SettingsService
    }

    ListModel {
        id: activeListModel
    }

    ListModel {
        id: historyListModel
    }

    NotificationServer {
        id: notificationServer

        keepOnReload: false
        imageSupported: true
        actionsSupported: true
        onNotification: (notification) => {
            if (notification.tracked)
                return ;

            notification.tracked = true;
            notification.closed.connect((reason) => {
                let nd = root.notificationObjects[notification.id];
                if (nd && nd.notification !== notification)
                    return ;

                if (nd)
                    nd.popup = false;

            });
            notification.summaryChanged.connect(() => {
                root.handleNotificationUpdate(notification);
            });
            notification.bodyChanged.connect(() => {
                root.handleNotificationUpdate(notification);
            });
            root.handleNotificationUpdate(notification);
        }
    }

}
