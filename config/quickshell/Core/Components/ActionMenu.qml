import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import qs.Core
import qs.Core.Components

ListView {
    id: root

    property var actionModel: []

    signal actionTriggered(int index)

    Layout.alignment: Qt.AlignHCenter
    Layout.preferredWidth: 64 * actionModel.length
    Layout.preferredHeight: 48
    currentIndex: 0
    width: 64 * actionModel.length
    height: 48
    orientation: ListView.Horizontal
    spacing: 0
    model: actionModel
    clip: true
    highlightFollowsCurrentItem: true
    highlightMoveDuration: Constants.animNormal
    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Right) {
            if (currentIndex + 1 < actionModel.length) {
                currentIndex++;
                event.accepted = true;
            }
        } else if (event.key === Qt.Key_Left) {
            if (currentIndex - 1 >= 0) {
                currentIndex--;
                event.accepted = true;
            }
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            root.actionTriggered(currentIndex);
            event.accepted = true;
        }
    }

    QQC2.ScrollBar.horizontal: QQC2.ScrollBar {
        policy: QQC2.ScrollBar.AlwaysOff
        active: true
    }

    highlight: Item {
        width: 64
        height: 48

        Rectangle {
            anchors.fill: parent
            anchors.margins: Constants.size3Xs
            radius: Constants.sizeSm
            color: Theme.accent
        }

    }

    delegate: Item {
        id: delegateRoot

        readonly property bool isCurrent: root.currentIndex === index

        width: 64
        height: 48

        Rectangle {
            anchors.fill: parent
            anchors.margins: Constants.size3Xs
            radius: Constants.sizeSm
            color: hoverHandler.hovered && !delegateRoot.isCurrent ? Theme.bgSecondary : "transparent"
        }

        SvgIcon {
            icon: modelData.icon
            iconColor: delegateRoot.isCurrent ? Theme.bg : (hoverHandler.hovered ? Theme.fg : Theme.muted)
            iconSize: Constants.sizeLg
            flat: true
            anchors.centerIn: parent

            Behavior on iconColor {
                ColorAnimation {
                    duration: Constants.animFast
                }

            }

        }

        ThemedTooltip {
            text: modelData.label
            visible: hoverHandler.hovered
        }

        HoverHandler {
            id: hoverHandler

            cursorShape: Qt.PointingHandCursor
            onHoveredChanged: {
                if (hovered)
                    root.currentIndex = index;

            }
        }

        TapHandler {
            id: tapHandler

            onTapped: {
                root.currentIndex = index;
                root.actionTriggered(index);
            }
        }

    }

}
