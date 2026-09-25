import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Clipboard.Components

ColumnLayout {
    id: root

    property var widget: null
    property string searchText: ""
    property alias initialFocusItem: searchField

    function closeWidget() {
        if (root.widget && typeof root.widget.close === "function")
            root.widget.close();
        else if (root.widget && root.widget.isOpen !== undefined)
            root.widget.isOpen = false;
        else
            AppState.activePopup = "";
    }

    function resetClipboard() {
        clipboardView.currentIndex = -1;
        searchField.text = "";
        ClipboardService.refresh();
        searchField.forceActiveFocus();
    }

    implicitWidth: 720
    implicitHeight: 480
    anchors.fill: parent
    spacing: Constants.sizeLg
    Component.onCompleted: {
        resetClipboard();
    }

    Item {
        id: topSearchContainer

        Layout.fillWidth: true
        Layout.preferredHeight: 40
        visible: !(SettingsService.barFramedMode || SettingsService.barConvexMode)
    }

    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        SearchEmptyState {
            anchors.centerIn: parent
            emptyVisible: ClipboardService.filteredModel.count === 0 && searchField.text === "" && !ClipboardService.isDeleting
            searchEmptyVisible: ClipboardService.filteredModel.count === 0 && searchField.text !== "" && !ClipboardService.isDeleting
            emptyText: "Clipboard is empty"
            searchEmptyText: "No results found"
        }

        ListView {
            id: clipboardView

            anchors.fill: parent
            clip: true
            model: ClipboardService.filteredModel
            spacing: Constants.sizeXs
            currentIndex: -1
            highlightResizeDuration: 0
            highlightMoveDuration: Constants.animNormal
            highlightFollowsCurrentItem: true
            Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Down) {
                    if ((SettingsService.barFramedMode || SettingsService.barConvexMode) && clipboardView.currentIndex === ClipboardService.filteredModel.count - 1) {
                        searchField.forceActiveFocus();
                        clipboardView.currentIndex = -1;
                    } else {
                        clipboardView.currentIndex = Math.min(clipboardView.currentIndex + 1, ClipboardService.filteredModel.count - 1);
                    }
                    event.accepted = true;
                } else if (event.key === Qt.Key_Up) {
                    if (!(SettingsService.barFramedMode || SettingsService.barConvexMode) && clipboardView.currentIndex === 0) {
                        searchField.forceActiveFocus();
                        clipboardView.currentIndex = -1;
                    } else {
                        clipboardView.currentIndex = Math.max(clipboardView.currentIndex - 1, 0);
                    }
                    event.accepted = true;
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    let idx = clipboardView.currentIndex;
                    if (idx >= 0) {
                        let item = ClipboardService.filteredModel.get(idx);
                        ClipboardService.copyItem(item.itemId, root.closeWidget);
                        event.accepted = true;
                    }
                } else if (event.key === Qt.Key_Delete) {
                    let idx = clipboardView.currentIndex;
                    if (idx >= 0 && ClipboardService.filteredModel.count > idx) {
                        let item = ClipboardService.filteredModel.get(idx);
                        ClipboardService.deleteItem(idx, item.fullLine);
                        event.accepted = true;
                    }
                }
            }

            highlight: Item {
                width: clipboardView.width
                height: clipboardView.currentItem ? clipboardView.currentItem.height : 44
                z: 1

                Rectangle {
                    anchors.fill: parent
                    radius: Constants.sizeLg
                    color: Theme.bgSecondary
                }

            }

            add: Transition {
                NumberAnimation {
                    properties: "opacity"
                    from: 0
                    to: 1
                    duration: Constants.animNormal
                    easing.type: Easing.OutQuint
                }

            }

            populate: Transition {
                NumberAnimation {
                    properties: "opacity"
                    from: 0
                    to: 1
                    duration: Constants.animNormal
                    easing.type: Easing.OutQuint
                }

            }

            remove: Transition {
                ParallelAnimation {
                    NumberAnimation {
                        property: "x"
                        to: clipboardView.width
                        duration: Constants.animNormal
                        easing.type: Easing.InCubic
                    }

                    NumberAnimation {
                        property: "opacity"
                        to: 0
                        duration: Constants.animNormal
                        easing.type: Easing.InQuad
                    }

                    NumberAnimation {
                        property: "scale"
                        to: 0.92
                        duration: Constants.animNormal
                        easing.type: Easing.InQuad
                    }

                }

            }

            removeDisplaced: Transition {
                SequentialAnimation {
                    PauseAnimation {
                        duration: Constants.animNormal
                    }

                    NumberAnimation {
                        properties: "y"
                        duration: Constants.animNormal
                        easing.type: Easing.OutQuint
                    }

                }

            }

            displaced: Transition {
                NumberAnimation {
                    properties: "y"
                    duration: Constants.animNormal
                    easing.type: Easing.OutQuint
                }

            }

            delegate: ClipboardItemDelegate {
                isCurrent: clipboardView.currentIndex === index && index >= 0
                onCopyRequested: function(reqId) {
                    ClipboardService.copyItem(reqId, root.closeWidget);
                }
                onDeleteRequested: function(fullLine) {
                    ClipboardService.deleteItem(index, fullLine);
                }

                Binding on itemText {
                    when: model.text !== undefined && model.text !== null
                    value: model.text
                }

                Binding on itemId {
                    when: model.itemId !== undefined && model.itemId !== null
                    value: model.itemId
                }

                Binding on itemFullLine {
                    when: model.fullLine !== undefined && model.fullLine !== null
                    value: model.fullLine
                }

                Binding on isImg {
                    when: model.isImage !== undefined && model.isImage !== null
                    value: model.isImage
                }

            }

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AlwaysOff
                active: true
            }

        }

    }

    Item {
        id: bottomSearchContainer

        Layout.fillWidth: true
        Layout.preferredHeight: 40
        visible: SettingsService.barFramedMode || SettingsService.barConvexMode
    }

    RowLayout {
        id: searchRow

        parent: (SettingsService.barFramedMode || SettingsService.barConvexMode) ? bottomSearchContainer : topSearchContainer
        anchors.fill: parent
        spacing: Constants.sizeXs

        ThemedSearchBar {
            id: searchField

            Layout.fillWidth: true
            preferredHeight: 40
            placeholderText: "Search clipboard history..."
            onSearchRequested: (text) => {
                return ClipboardService.filterClipboard(text);
            }
            customSize: Constants.sizeMd
            textField.Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Down) {
                    clipboardView.currentIndex = Math.min(clipboardView.currentIndex + 1, ClipboardService.filteredModel.count - 1);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Up) {
                    clipboardView.currentIndex = Math.max(clipboardView.currentIndex - 1, 0);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    let idx = clipboardView.currentIndex >= 0 ? clipboardView.currentIndex : 0;
                    if (ClipboardService.filteredModel.count > idx) {
                        let item = ClipboardService.filteredModel.get(idx);
                        ClipboardService.copyItem(item.itemId, root.closeWidget);
                        event.accepted = true;
                    }
                } else if (event.key === Qt.Key_Delete) {
                    let idx = clipboardView.currentIndex;
                    if (idx >= 0 && ClipboardService.filteredModel.count > idx) {
                        let item = ClipboardService.filteredModel.get(idx);
                        ClipboardService.deleteItem(idx, item.fullLine);
                        event.accepted = true;
                    }
                } else if (event.key === Qt.Key_Escape) {
                    root.closeWidget();
                    event.accepted = true;
                }
            }
        }

        SvgIconButton {
            icon: "trash"
            iconColor: Theme.accent
            iconSize: Constants.sizeXl
            visible: ClipboardService.filteredModel.count > 0
            onClicked: ClipboardService.clearHistory()
        }

    }

}
