import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Core
import qs.Core.Components

Rectangle {
    id: delegateRoot

    property var notifData
    property var notificationService
    property int itemIndex: -1
    property var currentTime
    property bool expanded: false

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

    width: ListView.view.width
    height: delegateLayout.implicitHeight + Constants.sizeLg * 2
    color: delegateMouseArea.containsMouse ? Theme.bgTertiary : Theme.bgSecondary
    radius: Constants.sizeXl
    border.width: 1
    border.color: delegateMouseArea.containsMouse ? Theme.accent : Theme.border

    MouseArea {
        id: delegateMouseArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (notificationService && itemIndex >= 0)
                notificationService.removeHistoryItem(itemIndex);

        }
    }

    RowLayout {
        id: delegateLayout

        anchors.fill: parent
        anchors.margins: Constants.sizeLg
        spacing: Constants.sizeLg

        NotificationIcon {
            id: iconContainer

            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: iconContainer.isUrgencyIcon ? Constants.sizeLg : Constants.size4Xl
            Layout.preferredHeight: iconContainer.isUrgencyIcon ? Constants.sizeLg : Constants.size4Xl
            notifData: delegateRoot.notifData
            bgColor: "transparent"
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                spacing: Constants.sizeXs

                ThemedText {
                    id: summaryText

                    text: delegateRoot.notifData ? delegateRoot.notifData.summary : ""
                    color: Theme.fg
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    maximumLineCount: delegateRoot.expanded ? 100 : 1
                    wrapMode: Text.Wrap
                }

                ThemedText {
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: 4
                    text: {
                        if (!delegateRoot.notifData)
                            return "";

                        let ts = delegateRoot.notifData.timestamp;
                        if (!ts)
                            return "Just now";

                        let n = Number(ts);
                        let d = new Date(n < 1e+10 ? n * 1000 : n);
                        return timeAgo(d, delegateRoot.currentTime);
                    }
                    color: Theme.muted
                    customSize: Constants.sizeXs + 2
                }

                SvgIconButton {
                    id: expandButton

                    Layout.alignment: Qt.AlignTop
                    iconSize: Constants.sizeSm
                    icon: delegateRoot.expanded ? "chevron-up" : "chevron-down"
                    visible: bodyText.truncated || summaryText.truncated || delegateRoot.expanded
                    onClicked: {
                        delegateRoot.expanded = !delegateRoot.expanded;
                    }
                }

            }

            ThemedText {
                id: bodyText

                text: delegateRoot.notifData ? delegateRoot.notifData.body : ""
                color: Theme.muted
                customSize: Constants.sizeXs + 2
                wrapMode: Text.Wrap
                Layout.fillWidth: true
                maximumLineCount: delegateRoot.expanded ? 100 : 2
                elide: Text.ElideRight
            }

        }

    }

    Behavior on scale {
        NumberAnimation {
            duration: Constants.animFast
            easing.type: Easing.OutQuint
        }

    }

    Behavior on border.color {
        ColorAnimation {
            duration: Constants.animNormal
        }

    }

}
