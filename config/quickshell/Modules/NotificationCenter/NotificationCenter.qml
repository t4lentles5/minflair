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
import qs.Modules.NotificationCenter.Components

Item {
    id: root

    property var notificationService
    property var currentTime: SystemInfoService.currentTime
    property bool controlCenterOpen: false
    property bool isClearingAll: false

    function startClearAllAnimation() {
        if (isClearingAll || !notificationService || historyView.count === 0)
            return ;

        isClearingAll = true;
    }

    onVisibleChanged: {
        if (!visible)
            isClearingAll = false;

    }
    implicitWidth: 400
    implicitHeight: 450

    ColumnLayout {
        anchors.fill: parent
        spacing: Constants.sizeLg

        RowLayout {
            Layout.fillWidth: true
            spacing: Constants.sizeXs

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Constants.size3Xs

                ThemedText {
                    text: "Notifications"
                    customSize: Constants.sizeLg
                    font.bold: true
                    color: Theme.fg
                }

                ThemedText {
                    text: (historyView.count > 0 && !root.isClearingAll) ? (historyView.count + (historyView.count === 1 ? " active notification" : " active notifications")) : "All caught up"
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
                    isActive: root.notificationService && root.notificationService.dndEnabled
                    icon: isActive ? "bell-off" : "bell"
                    iconColor: isActive ? Theme.fg : Theme.accent
                    iconSize: Constants.sizeSm
                    textIcon: isActive ? "Unmute" : "Mute"
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
                            root.startClearAllAnimation();

                    }
                    useCustomWidth: true
                    disabled: historyView.count === 0 || root.isClearingAll
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
                    visible: opacity > 0
                    opacity: (historyView.count === 0 && !root.isClearingAll) ? 1 : 0

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

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Constants.animNormal
                            easing.type: Easing.OutCubic
                        }

                    }

                }

                Item {
                    id: listContainer

                    anchors.fill: parent
                    visible: historyView.count > 0 || root.isClearingAll
                    opacity: root.isClearingAll ? 0 : 1
                    x: root.isClearingAll ? 40 : 0
                    scale: root.isClearingAll ? 0.94 : 1
                    transformOrigin: Item.Center

                    ListView {
                        id: historyView

                        anchors.fill: parent
                        interactive: true
                        model: notificationService ? notificationService.historyList : null
                        spacing: Constants.sizeXs

                        displaced: Transition {
                            NumberAnimation {
                                properties: "y"
                                duration: Constants.animNormal
                                easing.type: Easing.OutQuint
                            }

                        }

                        delegate: NotificationItemDelegate {
                            notifData: model.notifData
                            notificationService: root.notificationService
                            itemIndex: index
                            currentTime: root.currentTime
                        }

                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Constants.animFast
                            easing.type: Easing.OutQuad
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
                            onRunningChanged: {
                                if (!running && root.isClearingAll) {
                                    if (root.notificationService)
                                        root.notificationService.clearHistory();

                                    root.isClearingAll = false;
                                }
                            }
                        }

                    }

                }

            }

        }

    }

}
