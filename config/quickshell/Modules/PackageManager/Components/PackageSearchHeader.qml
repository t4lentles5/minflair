import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Core
import qs.Core.Components

ColumnLayout {
    id: headerRoot

    property var managerRoot
    property alias searchField: searchField

    Layout.fillWidth: true
    Layout.leftMargin: Constants.sizeLg
    Layout.rightMargin: Constants.sizeLg
    Layout.topMargin: Constants.sizeLg
    Layout.bottomMargin: 0
    spacing: Constants.sizeSm

    // Search bar row (flat, full-width, with count on right)
    RowLayout {
        Layout.fillWidth: true
        spacing: Constants.sizeMd
        visible: managerRoot && managerRoot.actionMode !== "update"

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Constants.size4Xl
            color: "transparent"
            radius: Constants.sizeMd

            ThemedSearchBar {
                id: searchField

                anchors.fill: parent
                customSize: Constants.sizeMd
                autoFocus: false
                placeholderText: (managerRoot && managerRoot.actionMode === "remove") ? "Search installed..." : "Search to install..."
                onSearchRequested: (text) => {
                    if (managerRoot) {
                        managerRoot.searchText = text;
                        managerRoot.restartDebounceTimer();
                    }
                }
                textField.onTextChanged: {
                    if (searchField.textField.text.length > 0 && !searchField.textField.activeFocus)
                        searchField.textField.forceActiveFocus();

                }
                textField.Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Escape) {
                        if (managerRoot && managerRoot.contentComp)
                            managerRoot.contentComp.focusListView();
                        else
                            searchField.textField.focus = false;
                        event.accepted = true;
                        return ;
                    }
                    if (managerRoot)
                        managerRoot.handleKeyPress(event, true);

                }
            }

        }

    }

    // Pill filters
    RowLayout {
        Layout.fillWidth: true
        spacing: Constants.sizeSm

        Repeater {
            model: [{
                "index": 0,
                "label": "Discover",
                "val": "install"
            }, {
                "index": 1,
                "label": "Installed",
                "val": "remove"
            }, {
                "index": 2,
                "label": "Updates",
                "val": "update"
            }]

            delegate: Rectangle {
                property bool isActive: managerRoot && managerRoot.activeTab === modelData.index

                height: Constants.size3Xl
                width: tabText.implicitWidth + Constants.sizeXl * 2
                radius: height / 2
                color: isActive ? Theme.accent : "transparent"
                border.color: isActive ? Theme.accent : Theme.border
                border.width: 1

                ThemedText {
                    id: tabText

                    anchors.centerIn: parent
                    text: modelData.label
                    customSize: Constants.sizeSm
                    color: isActive ? Theme.bg : Theme.fg
                }

                HoverHandler {
                    id: tabHover

                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: {
                        if (!managerRoot)
                            return ;

                        let val = modelData.val;
                        if (managerRoot.actionMode === val)
                            return ;

                        managerRoot.actionMode = val;
                        managerRoot.selectedPackages = [];
                        managerRoot.selectedPackageObjects = {
                        };
                        managerRoot.allResults = [];
                        managerRoot.resultsModel.clear();
                        searchField.text = "";
                        managerRoot.searchText = "";
                        managerRoot.doSearch("");
                        managerRoot.triggerDelayedFocus();
                    }
                }

                Behavior on color {
                    ColorAnimation {
                        duration: Constants.animFast
                    }

                }

            }

        }

        Item {
            Layout.fillWidth: true
        }

        ThemedText {
            Layout.alignment: Qt.AlignVCenter
            visible: text !== ""
            text: {
                if (!managerRoot)
                    return "";

                if (managerRoot.isSearching)
                    return "···";

                if (managerRoot.actionMode === "update")
                    return managerRoot.allResults.length + " updates available";

                if (managerRoot.searchText.length > 0)
                    return managerRoot.resultsModel.count + " found";

                if (managerRoot.actionMode === "remove")
                    return managerRoot.resultsModel.count + " installed";

                return "";
            }
            color: Theme.muted
            customSize: Constants.sizeSm
        }

    }

}
