import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Core
import qs.Core.Components
import qs.Core.Services

Rectangle {
    id: sidebarRoot

    property var activeId
    property var fullModel: []
    property Item activeItem: null
    property bool _isInitialized: false
    property bool useSameIconForActive: false

    signal tabClicked(var id)

    Component.onCompleted: {
        Qt.callLater(() => {
            _isInitialized = true;
        });
    }
    Layout.preferredWidth: 64
    Layout.maximumWidth: 64
    Layout.minimumWidth: 64
    Layout.fillHeight: true
    color: Theme.bg

    ColumnLayout {
        id: mainLayout

        anchors.fill: parent
        anchors.topMargin: Constants.sizeLg
        anchors.bottomMargin: Constants.sizeLg
        anchors.leftMargin: Constants.sizeLg
        anchors.rightMargin: 0
        spacing: Constants.sizeMd

        Card {
            Layout.fillWidth: true
            Layout.fillHeight: true
            backgroundColor: Theme.bgSecondary
            cardRadius: Constants.sizeLg
            contentPadding: Constants.sizeXs

            ColumnLayout {
                anchors.fill: parent
                spacing: Constants.sizeMd

                Repeater {
                    id: tabRepeater

                    model: fullModel

                    delegate: ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Item {
                            Layout.fillHeight: true
                            visible: index === sidebarRoot.fullModel.length - 1
                        }

                        Item {
                            id: delegateRoot

                            property bool isActive: sidebarRoot.activeId === modelData.index
                            property bool isHovered: hoverHandler.hovered
                            property bool isPressed: tapHandler.pressed

                            onIsActiveChanged: {
                                if (isActive)
                                    sidebarRoot.activeItem = delegateRoot;

                            }
                            Component.onCompleted: {
                                if (isActive)
                                    sidebarRoot.activeItem = delegateRoot;

                            }
                            Layout.fillWidth: true
                            Layout.preferredHeight: width

                            ThemedTooltip {
                                text: modelData.label
                                visible: delegateRoot.isHovered
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: Constants.sizeSm
                                color: delegateRoot.isActive || delegateRoot.isHovered ? Theme.bgSecondary : "transparent"
                                scale: delegateRoot.isPressed ? 0.95 : 1

                                SvgIcon {
                                    anchors.centerIn: parent
                                    icon: !sidebarRoot.useSameIconForActive && delegateRoot.isActive ? (modelData.icon + "-filled") : modelData.icon
                                    iconSize: Constants.sizeXl
                                    flat: true
                                    iconColor: delegateRoot.isActive ? Theme.accent : (delegateRoot.isHovered ? Theme.fg : Theme.muted)

                                    Behavior on iconColor {
                                        ColorAnimation {
                                            duration: Constants.animFast
                                        }

                                    }

                                }

                                Behavior on color {
                                    ColorAnimation {
                                        duration: Constants.animFast
                                    }

                                }

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: Constants.animFast
                                        easing.type: Easing.OutQuart
                                    }

                                }

                            }

                            TapHandler {
                                id: tapHandler

                                onTapped: sidebarRoot.tabClicked(modelData.index)
                            }

                            HoverHandler {
                                id: hoverHandler

                                cursorShape: Qt.PointingHandCursor
                            }

                        }

                    }

                }

            }

        }

    }

}
