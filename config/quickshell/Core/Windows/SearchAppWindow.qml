import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Windows

AppWindow {
    id: root

    property string placeholderText: "Search..."
    property string searchText: ""
    property var tabsModel: []
    property string activeTabValue: ""
    property int activeTabIndex: 0
    property string statusText: ""
    property bool isSearching: false
    property bool hideSearchBar: false
    property bool enableTabTransition: true
    default property alias viewContent: transitionView.content
    property alias overlayData: overlayContainer.data
    property alias searchFieldRef: searchField

    signal searchRequested(string text)
    signal tabClicked(string val, int index)
    signal escapePressed()
    signal searchKeyPress(var event, bool fromSearch)

    function focusSearch() {
        searchField.textField.forceActiveFocus();
        searchField.textField.selectAll();
    }

    contentPadding: 0
    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Slash) {
            if (!searchField.textField.activeFocus) {
                focusSearch();
                event.accepted = true;
            }
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Header
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Constants.sizeLg
                Layout.rightMargin: Constants.sizeLg
                Layout.topMargin: Constants.sizeLg
                spacing: Constants.sizeSm

                // Search Bar
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Constants.sizeMd
                    visible: !root.hideSearchBar

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
                            placeholderText: root.placeholderText
                            text: root.searchText
                            onSearchRequested: (text) => {
                                root.searchText = text;
                                root.searchRequested(text);
                            }
                            textField.onTextChanged: {
                                if (searchField.textField.text.length > 0 && !searchField.textField.activeFocus)
                                    searchField.textField.forceActiveFocus();

                            }
                            textField.Keys.onPressed: function(event) {
                                if (event.key === Qt.Key_Escape) {
                                    root.escapePressed();
                                    event.accepted = true;
                                    return ;
                                }
                                root.searchKeyPress(event, true);
                            }
                        }

                    }

                }

                // Tabs
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Constants.sizeSm

                    ScrollView {
                        Layout.fillWidth: true
                        Layout.preferredHeight: tabRow.implicitHeight + Constants.sizeMd
                        contentWidth: tabRow.implicitWidth
                        clip: true
                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                        RowLayout {
                            id: tabRow

                            spacing: Constants.sizeSm

                            Repeater {
                                model: root.tabsModel

                                delegate: Rectangle {
                                    property bool isActive: root.activeTabValue === (modelData.val !== undefined ? modelData.val : modelData)

                                    height: Constants.size3Xl
                                    width: tabText.implicitWidth + Constants.sizeXl * 2
                                    radius: height / 2
                                    color: isActive ? Theme.accent : "transparent"
                                    border.color: isActive ? Theme.accent : Theme.border
                                    border.width: 1

                                    ThemedText {
                                        id: tabText

                                        anchors.centerIn: parent
                                        text: modelData.label !== undefined ? modelData.label : modelData
                                        customSize: Constants.sizeSm
                                        color: isActive ? Theme.bg : Theme.fg
                                    }

                                    HoverHandler {
                                        cursorShape: Qt.PointingHandCursor
                                    }

                                    TapHandler {
                                        onTapped: {
                                            let val = modelData.val !== undefined ? modelData.val : modelData;
                                            if (root.activeTabValue === val)
                                                return ;

                                            root.activeTabValue = val;
                                            root.activeTabIndex = index;
                                            root.tabClicked(val, index);
                                        }
                                    }

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: Constants.animFast
                                        }

                                    }

                                }

                            }

                        }

                    }

                    // Spacer
                    Item {
                        Layout.fillWidth: true
                    }

                    ThemedText {
                        Layout.alignment: Qt.AlignVCenter
                        visible: text !== ""
                        text: root.isSearching ? "..." : root.statusText
                        color: Theme.muted
                        customSize: Constants.sizeSm
                    }

                }

            }

            PageTransitionView {
                id: transitionView

                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.leftMargin: Constants.sizeLg
                Layout.rightMargin: Constants.sizeLg
                activeIndex: root.enableTabTransition ? root.activeTabIndex : 0
            }

        }

        Item {
            id: overlayContainer

            anchors.fill: parent
            z: 100
        }

    }

}
