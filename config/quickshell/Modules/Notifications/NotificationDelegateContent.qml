import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Modules.Notifications.Components

Item {
    id: root

    property var notifData
    property bool isConvex: false
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
    readonly property real textContentHeight: {
        let h = 0;
        if (summaryText.visible && summaryText.text !== "")
            h += summaryText.implicitHeight;

        if (bodyText.visible && bodyText.text !== "")
            h += (h > 0 ? textColumn.spacing : 0) + bodyText.implicitHeight;

        if (osdBar.visible)
            h += (h > 0 ? textColumn.spacing : 0) + osdBar.height;

        return h > 0 ? h : Constants.size2Xl;
    }
    readonly property int calculatedIconSize: Math.max(Constants.sizeLg, Math.round(textContentHeight))

    implicitHeight: layout.implicitHeight

    RowLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Constants.sizeSm
        spacing: Constants.sizeSm

        NotificationIcon {
            id: iconContainer

            Layout.alignment: iconContainer.isUrgencyIcon ? (Qt.AlignTop | Qt.AlignLeft) : Qt.AlignVCenter
            Layout.topMargin: iconContainer.isUrgencyIcon ? Constants.size3Xs : 0
            Layout.preferredWidth: iconContainer.isUrgencyIcon ? Constants.sizeLg : root.calculatedIconSize
            Layout.preferredHeight: iconContainer.isUrgencyIcon ? Constants.sizeLg : root.calculatedIconSize
            notifData: root.notifData
            bgColor: root.isConvex ? "transparent" : Theme.bgSecondary
        }

        ColumnLayout {
            id: textColumn

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            ThemedText {
                id: summaryText

                Layout.fillWidth: true
                text: root.parsedNotif.title
                color: Theme.fg
                customSize: Constants.sizeSm
                font.weight: Font.DemiBold
                maximumLineCount: 1
                elide: Text.ElideRight
                wrapMode: Text.Wrap
                visible: root.parsedNotif.title !== ""
            }

            ThemedText {
                id: bodyText

                Layout.fillWidth: true
                text: root.parsedNotif.message
                wrapMode: Text.Wrap
                color: Theme.muted
                customSize: Constants.sizeXs + 2
                maximumLineCount: 2
                elide: Text.ElideRight
                visible: root.parsedNotif.message !== ""
            }

            OsdProgressBar {
                id: osdBar

                Layout.fillWidth: true
                notifData: root.notifData
            }

        }

    }

    NotificationProgressBar {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottomMargin: 0
        anchors.leftMargin: Constants.sizeSm
        anchors.rightMargin: Constants.sizeSm
        notifData: root.notifData
    }

}
