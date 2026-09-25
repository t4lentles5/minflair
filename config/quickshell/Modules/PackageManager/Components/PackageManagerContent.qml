import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Core
import qs.Core.Components
import qs.Core.Utils

ColumnLayout {
    id: contentRoot

    property var managerRoot

    function setSearchText(text) {
    }

    function focusSearchField() {
    }

    function focusListView() {
        if (pkgView.visible)
            pkgView.forceActiveFocus();

    }

    function getListView() {
        return pkgView;
    }

    spacing: 0

    Item {
        Layout.margins: 0
        Layout.fillWidth: true
        Layout.fillHeight: true

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                GhostEmptyState {
                    anchors.centerIn: parent
                    visible: managerRoot.resultsModel.count === 0 && !managerRoot.isSearching && !managerRoot.isDebounceTimerRunning() && !(managerRoot.actionMode === "install" && managerRoot.searchText.length < 2)
                    icon: managerRoot.actionMode === "update" ? "check" : "ghost"
                    iconColor: managerRoot.actionMode === "update" ? Theme.accent : Theme.muted
                    text: managerRoot.actionMode === "update" ? "System is up to date" : "No packages found"
                    isAnimating: visible && managerRoot.actionMode !== "update"
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    visible: managerRoot.isSearching

                    SvgIcon {
                        icon: "reload"
                        iconColor: Theme.accent
                        iconSize: 36
                        flat: true
                        Layout.alignment: Qt.AlignHCenter

                        RotationAnimation on rotation {
                            from: 0
                            to: 360
                            duration: 1000
                            loops: Animation.Infinite
                            running: managerRoot.isSearching
                        }

                    }

                    ThemedText {
                        text: "Searching"
                        color: Theme.fg
                        font.bold: true
                        customSize: Constants.sizeMd
                        Layout.alignment: Qt.AlignHCenter
                    }

                    TypewriterText {
                        text: "for packages..."
                        color: Theme.muted
                        customSize: Constants.sizeSm
                        Layout.alignment: Qt.AlignHCenter
                        typeInterval: 50
                    }

                }

                GridView {
                    id: pkgView

                    property int cols: 3

                    anchors.fill: parent
                    anchors.leftMargin: 0
                    anchors.rightMargin: -Constants.sizeSm
                    anchors.bottomMargin: Constants.sizeLg
                    clip: true
                    model: managerRoot.resultsModel
                    cellWidth: width / cols
                    cellHeight: 160
                    currentIndex: -1
                    visible: managerRoot.resultsModel.count > 0 && !managerRoot.isSearching
                    Keys.onPressed: function(event) {
                        managerRoot.handleKeyPress(event, false);
                    }

                    add: Transition {
                        NumberAnimation {
                            property: "opacity"
                            from: 0
                            to: 1
                            duration: Constants.animNormal
                            easing.type: Easing.OutQuint
                        }

                    }

                    remove: Transition {
                        NumberAnimation {
                            property: "opacity"
                            to: 0
                            duration: Constants.animFast
                        }

                    }

                    removeDisplaced: Transition {
                        NumberAnimation {
                            properties: "y"
                            duration: Constants.animFast
                            easing.type: Easing.OutExpo
                        }

                    }

                    addDisplaced: Transition {
                        NumberAnimation {
                            properties: "y"
                            duration: Constants.animNormal
                            easing.type: Easing.OutExpo
                        }

                    }

                    displaced: Transition {
                        NumberAnimation {
                            properties: "y"
                            duration: Constants.animNormal
                            easing.type: Easing.OutExpo
                        }

                    }

                    populate: Transition {
                        NumberAnimation {
                            property: "opacity"
                            from: 0
                            to: 1
                            duration: Constants.animNormal
                            easing.type: Easing.OutQuint
                        }

                    }

                    delegate: PackageDelegate {
                        rootRef: managerRoot
                        listViewRef: pkgView
                    }

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AlwaysOff
                        active: true
                    }

                }

                // Floating Action Button
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    anchors.margins: Constants.sizeLg
                    width: actionLayout.implicitWidth + Constants.size3Xl
                    height: 48
                    radius: 24
                    color: Theme.accent
                    visible: managerRoot.selectedPackages.length > 0
                    opacity: visible ? 1 : 0
                    scale: execTap.pressed ? 0.95 : (visible ? 1 : 0.8)
                    z: 10

                    RowLayout {
                        id: actionLayout

                        anchors.centerIn: parent
                        spacing: Constants.sizeSm

                        ThemedText {
                            text: managerRoot.selectedPackages.length + " selected"
                            font.bold: true
                            color: Theme.bg
                            customSize: Constants.sizeSm
                        }

                        Rectangle {
                            Layout.preferredWidth: 2
                            Layout.preferredHeight: 12
                            color: Theme.bg
                            opacity: 0.3
                            radius: 1
                        }

                        RowLayout {
                            spacing: 4

                            SvgIcon {
                                icon: managerRoot.actionMode === "install" ? "download" : managerRoot.actionMode === "update" ? "update" : "trash"
                                iconSize: 16
                                iconColor: Theme.bg
                                flat: true
                            }

                            ThemedText {
                                text: managerRoot.actionMode === "install" ? "Install" : managerRoot.actionMode === "update" ? "Update" : "Remove"
                                font.bold: true
                                color: Theme.bg
                                customSize: Constants.sizeSm
                            }

                        }

                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: Theme.bg
                        opacity: execHover.hovered ? 0.15 : 0

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Constants.animFast
                            }

                        }

                    }

                    HoverHandler {
                        id: execHover

                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        id: execTap

                        onTapped: managerRoot.executeBatch()
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Constants.animFast
                        }

                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: Constants.animFast
                            easing.type: Easing.OutBack
                        }

                    }

                }

            }

        }

    }

}
