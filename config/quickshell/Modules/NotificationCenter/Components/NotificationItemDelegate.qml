import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Core
import qs.Core.Components
import qs.Modules.Notifications.Components

Rectangle {
    id: delegateRoot

    property var notifData
    property var notificationService
    property int itemIndex: -1
    property var currentTime
    property bool expanded: false
    property bool isDeletingAnim: false
    readonly property real targetHeight: isDeletingAnim ? 0 : (delegateLayout.implicitHeight + Constants.sizeLg * 2)
    readonly property var parsedNotif: {
        if (!notifData)
            return {
            "app": "",
            "title": "",
            "message": ""
        };

        let app = (notifData.appName || "").trim();
        let sum = (notifData.summary || "").trim();
        let body = (notifData.body || "").trim();
        // Case 1: summary is generic (e.g. "WhatsApp Web", "WhatsApp") and body contains sender + message separated by newline
        if ((sum.toLowerCase().includes("whatsapp") || (app !== "" && sum.toLowerCase() === app.toLowerCase())) && body.includes("\n")) {
            let lines = body.split("\n").filter(function(l) {
                return l.trim().length > 0;
            });
            if (lines.length >= 2)
                return {
                "app": sum !== "" ? sum : app,
                "title": lines[0].trim(),
                "message": lines.slice(1).join("\n").trim()
            };

        }
        // Case 2: summary is generic and body has "Sender: Message"
        if ((sum.toLowerCase().includes("whatsapp") || (app !== "" && sum.toLowerCase() === app.toLowerCase())) && body.includes(": ")) {
            let colonIdx = body.indexOf(": ");
            let sender = body.substring(0, colonIdx).trim();
            let msg = body.substring(colonIdx + 2).trim();
            if (sender.length > 0 && msg.length > 0)
                return {
                "app": sum !== "" ? sum : app,
                "title": sender,
                "message": msg
            };

        }
        // Case 3: We have a valid appName distinct from summary and System
        let hasDistinctApp = app !== "" && app !== "System" && app.toLowerCase() !== sum.toLowerCase();
        return {
            "app": hasDistinctApp ? app : (sum.toLowerCase().includes("whatsapp") ? sum : ""),
            "title": sum,
            "message": body
        };
    }

    function timeAgo(date, now) {
        if (!date || isNaN(date.getTime()) || !now || isNaN(now.getTime()))
            return "...";

        let diff = Math.floor((now.getTime() - date.getTime()) / 1000);
        if (diff < 60)
            return "Just now";

        if (diff < 3600)
            return Math.floor(diff / 60) + "m ago";

        if (diff < 86400)
            return Math.floor(diff / 3600) + "h ago";

        return Math.floor(diff / 86400) + "d ago";
    }

    function startDeleteAnimation() {
        if (isDeletingAnim)
            return ;

        isDeletingAnim = true;
    }

    width: ListView.view ? ListView.view.width : 400
    height: targetHeight
    color: delegateMouseArea.containsMouse && !delegateRoot.isDeletingAnim ? Theme.bgSecondary : Theme.bgTertiary
    radius: Constants.sizeXl
    z: isDeletingAnim ? 1 : 2
    clip: true
    opacity: isDeletingAnim ? 0 : 1

    Item {
        id: delegateContent

        anchors.fill: parent
        x: delegateRoot.isDeletingAnim ? 36 : 0
        scale: delegateRoot.isDeletingAnim ? 0.94 : 1
        transformOrigin: Item.Center

        MouseArea {
            id: delegateMouseArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            enabled: !delegateRoot.isDeletingAnim
            onClicked: delegateRoot.startDeleteAnimation()
        }

        RowLayout {
            id: delegateLayout

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Constants.sizeLg
            spacing: Constants.sizeSm

            NotificationIcon {
                id: iconContainer

                Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                Layout.topMargin: Constants.size3Xs
                Layout.preferredWidth: iconContainer.isUrgencyIcon ? Constants.sizeLg : Constants.size3Xl
                Layout.preferredHeight: iconContainer.isUrgencyIcon ? Constants.sizeLg : Constants.size3Xl
                notifData: delegateRoot.notifData
                bgColor: "transparent"
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                spacing: Constants.size3Xs

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Constants.sizeXs

                    ThemedText {
                        id: summaryText

                        text: delegateRoot.parsedNotif.title
                        color: Theme.fg
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        maximumLineCount: delegateRoot.expanded ? 100 : 1
                        wrapMode: Text.Wrap
                    }

                    ThemedText {
                        Layout.alignment: Qt.AlignTop
                        Layout.topMargin: Constants.size2Xs
                        text: {
                            if (!delegateRoot.notifData)
                                return "";

                            let ts = delegateRoot.notifData.timestamp;
                            if (!ts)
                                return "Just now";

                            let n = Number(ts);
                            let d = new Date(n < 1e+10 ? n * 1000 : n);
                            return delegateRoot.timeAgo(d, delegateRoot.currentTime);
                        }
                        color: Theme.muted
                        customSize: Constants.sizeXs + 2
                    }

                    SvgIconButton {
                        id: expandButton

                        Layout.alignment: Qt.AlignVCenter
                        padding: Constants.size2Xs
                        iconSize: Constants.sizeXs + 2
                        icon: "chevron-down"
                        iconColor: Theme.muted
                        rotation: delegateRoot.expanded ? 180 : 0
                        visible: bodyText.truncated || summaryText.truncated || delegateRoot.expanded
                        enabled: !delegateRoot.isDeletingAnim
                        flat: true
                        onClicked: {
                            delegateRoot.expanded = !delegateRoot.expanded;
                        }

                        Behavior on rotation {
                            NumberAnimation {
                                duration: Constants.animNormal
                                easing.type: Easing.OutQuint
                            }

                        }

                    }

                }

                ThemedText {
                    id: bodyText

                    text: delegateRoot.parsedNotif.message
                    color: Theme.muted
                    customSize: Constants.sizeXs + 2
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                    maximumLineCount: delegateRoot.expanded ? 100 : 2
                    elide: Text.ElideRight
                    visible: text !== ""
                }

            }

        }

        Behavior on x {
            NumberAnimation {
                duration: Constants.animFast
                easing.type: Easing.OutCubic
            }

        }

        Behavior on scale {
            NumberAnimation {
                duration: Constants.animFast
                easing.type: Easing.OutCubic
            }

        }

    }

    Behavior on color {
        ColorAnimation {
            duration: Constants.animFast
        }

    }

    Behavior on height {
        NumberAnimation {
            duration: delegateRoot.isDeletingAnim ? 180 : Constants.animNormal
            easing.type: delegateRoot.isDeletingAnim ? Easing.InOutCubic : Easing.OutQuint
            onRunningChanged: {
                if (!running && delegateRoot.isDeletingAnim) {
                    if (delegateRoot.notificationService) {
                        if (delegateRoot.notifData && delegateRoot.notifData.notificationId)
                            delegateRoot.notificationService.removeNotification(delegateRoot.notifData.notificationId);
                        else if (delegateRoot.itemIndex >= 0)
                            delegateRoot.notificationService.removeHistoryItem(delegateRoot.itemIndex);
                    }
                }
            }
        }

    }

    Behavior on opacity {
        NumberAnimation {
            duration: Constants.animFast
            easing.type: Easing.OutQuad
        }

    }

}
