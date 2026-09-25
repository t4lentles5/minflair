import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Core.Windows
import qs.Modules.ControlCenter.Widgets.NotificationCenter.Components

Card {
    id: root

    property var notificationService
    property var currentTime: SystemInfoService.currentTime
    property bool controlCenterOpen: false

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

    implicitWidth: 400

    ColumnLayout {
        id: mainCol

        anchors.fill: parent
        spacing: Constants.sizeLg

        RowLayout {
            Layout.fillWidth: true
            spacing: Constants.sizeXs

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                ThemedText {
                    text: "Notifications"
                    customSize: Constants.sizeLg
                    font.bold: true
                    color: Theme.fg
                }

                ThemedText {
                    text: historyView.count > 0 ? (historyView.count + (historyView.count === 1 ? " active notification" : " active notifications")) : "All caught up"
                    customSize: Constants.sizeXs + 2
                    color: Theme.muted
                }

            }

            Item {
                Layout.fillWidth: true
            }

            RowLayout {
                spacing: Constants.sizeXs
                Layout.alignment: Qt.AlignVCenter

                SvgIconButton {
                    icon: (root.notificationService && root.notificationService.dndEnabled) ? "bell-off" : "bell"
                    iconColor: (root.notificationService && root.notificationService.dndEnabled) ? Theme.muted : Theme.accent
                    iconSize: Constants.sizeSm
                    textIcon: (root.notificationService && root.notificationService.dndEnabled) ? "Unmute" : "Mute"
                    textIconSize: Constants.sizeSm
                    useCustomWidth: true
                    onClicked: {
                        if (root.notificationService)
                            root.notificationService.dndEnabled = !root.notificationService.dndEnabled;

                    }
                }

                SvgIconButton {
                    icon: "trash"
                    iconSize: Constants.sizeSm
                    iconColor: Theme.accent
                    textIcon: "Clear All"
                    textIconSize: Constants.sizeSm
                    onClicked: {
                        if (notificationService && historyView.count > 0)
                            notificationService.clearHistory();

                    }
                    useCustomWidth: true
                    disabled: historyView.count === 0
                }

            }

        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Constants.sizeXs

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ColumnLayout {
                    id: emptyState

                    anchors.centerIn: parent
                    spacing: Constants.sizeSm
                    visible: historyView.count === 0

                    SvgIcon {
                        icon: "bell"
                        iconSize: Constants.size5Xl
                        iconColor: Theme.muted
                        Layout.alignment: Qt.AlignHCenter
                        flat: true
                    }

                    ThemedText {
                        text: "All caught up!"
                        font.bold: true
                        color: Theme.fg
                        Layout.alignment: Qt.AlignHCenter
                    }

                    ThemedText {
                        text: "No new notifications at the moment."
                        customSize: Constants.sizeXs + 2
                        color: Theme.muted
                        Layout.alignment: Qt.AlignHCenter
                    }

                }

                ListView {
                    id: historyView

                    anchors.fill: parent
                    interactive: true
                    model: notificationService ? notificationService.historyList : null
                    spacing: Constants.sizeXs

                    remove: Transition {
                        NumberAnimation {
                            property: "x"
                            to: historyView.width
                            duration: Constants.animSlow
                            easing.type: Easing.InExpo
                        }

                        NumberAnimation {
                            property: "opacity"
                            to: 0
                            duration: Constants.animSlow
                        }

                    }

                    removeDisplaced: Transition {
                        SequentialAnimation {
                            PauseAnimation {
                                duration: Constants.animSlow
                            }

                            NumberAnimation {
                                properties: "y"
                                duration: Constants.animSlow
                                easing.type: Easing.OutExpo
                            }

                        }

                    }

                    delegate: NotificationItemDelegate {
                        notifData: model.notifData
                        notificationService: root.notificationService
                        itemIndex: index
                        currentTime: root.currentTime
                    }

                }

            }

        }

    }

}
