import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Core
import qs.Core.Components
import qs.Core.Services

SettingRowTemplate {
    id: root

    property alias customSize: root.labelSize
    property var model: []
    property int currentIndex: 0
    property int comboWidth: 160
    property string fallbackText: "Auto"
    property var iconMap: ({
    })
    property var textMap: ({
    })
    property bool searchable: false
    property var _filteredModel: root.model

    signal activated(int index)

    function closePopup() {
        if (internalCombo && internalCombo.popup && internalCombo.popup.visible)
            internalCombo.popup.close();

    }

    onVisibleChanged: {
        if (!visible)
            closePopup();

    }

    ComboBox {
        id: internalCombo

        function updateIndex() {
            if (root.searchable && root.model) {
                let activeStr = root.model[root.currentIndex];
                let idx = root._filteredModel.indexOf(activeStr);
                internalCombo.currentIndex = Math.max(0, idx);
            } else {
                internalCombo.currentIndex = root.currentIndex;
            }
        }

        z: 10
        opacity: root.enabled ? 1 : 0.5
        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
        implicitWidth: root.comboWidth
        implicitHeight: Constants.size4Xl
        model: root.searchable ? root._filteredModel : root.model
        onActivated: (index) => {
            if (root.searchable) {
                let selectedItem = root._filteredModel[index];
                let originalIndex = root.model.indexOf(selectedItem);
                if (originalIndex !== -1)
                    root.activated(originalIndex);

            } else {
                root.activated(index);
            }
        }
        Keys.onUpPressed: (event) => {
            event.accepted = true;
        }
        Keys.onDownPressed: (event) => {
            event.accepted = true;
        }
        Component.onCompleted: {
            internalCombo.updateIndex();
        }

        Connections {
            function onCurrentIndexChanged() {
                Qt.callLater(internalCombo.updateIndex);
            }

            function onModelChanged() {
                Qt.callLater(internalCombo.updateIndex);
            }

            function on_FilteredModelChanged() {
                if (root.searchable)
                    Qt.callLater(internalCombo.updateIndex);

            }

            target: root
        }

        Connections {
            function onModelChanged() {
                Qt.callLater(internalCombo.updateIndex);
            }

            target: internalCombo
        }

        HoverHandler {
            cursorShape: Qt.PointingHandCursor
        }

        indicator: SvgIcon {
            x: internalCombo.width - width - 10
            y: (internalCombo.height - height) / 2
            flat: true
            icon: "chevron-down"
            iconSize: 13
            iconColor: internalCombo.popup.visible ? Theme.accent : Theme.muted
            rotation: internalCombo.popup.visible ? 180 : 0

            Behavior on rotation {
                NumberAnimation {
                    duration: Constants.animNormal
                    easing.type: Easing.OutBack
                }

            }

            Behavior on iconColor {
                ColorAnimation {
                    duration: Constants.animFast
                }

            }

        }

        contentItem: RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 30
            spacing: Constants.sizeXs

            ThemedText {
                Layout.fillWidth: true
                text: {
                    let txt = root.searchable && root.model ? root.model[root.currentIndex] : internalCombo.displayText;
                    if (!txt)
                        return root.fallbackText;

                    if (root.textMap && typeof txt === "string" && root.textMap[txt] !== undefined)
                        return root.textMap[txt];

                    return txt.split('-').map((word) => {
                        return word.charAt(0).toUpperCase() + word.slice(1);
                    }).join('-');
                }
                font.weight: Font.DemiBold
                customSize: root.customSize
                color: internalCombo.popup.visible ? Theme.accent : Theme.fg
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter

                Behavior on color {
                    ColorAnimation {
                        duration: Constants.animFast
                    }

                }

            }

        }

        background: Rectangle {
            color: internalCombo.down || internalCombo.hovered || internalCombo.popup.visible ? Theme.bgTertiary : Theme.bgSecondary
            radius: Constants.sizeXs
            border.width: 1
            border.color: internalCombo.popup.visible ? Theme.accent : Theme.border

            Behavior on color {
                ColorAnimation {
                    duration: Constants.animFast
                }

            }

            Behavior on border.color {
                ColorAnimation {
                    duration: Constants.animFast
                }

            }

        }

        popup: Popup {
            width: internalCombo.width
            implicitHeight: Math.min(contentItem.implicitHeight + (padding * 2), 200)
            padding: Constants.sizeXs
            onAboutToShow: {
                if (root.searchable) {
                    popupSearchInput.text = "";
                    popupSearchInput.forceActiveFocus();
                }
                popupListView.updateCurrentIndex();
            }
            onClosed: {
                if (root.searchable)
                    root._filteredModel = root.model;

            }
            transformOrigin: Item.Top

            enter: Transition {
                NumberAnimation {
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: Constants.animFast
                }

                NumberAnimation {
                    property: "scale"
                    from: 0.95
                    to: 1
                    duration: Constants.animNormal
                    easing.type: Easing.OutBack
                }

            }

            exit: Transition {
                NumberAnimation {
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: Constants.animFast
                }

                NumberAnimation {
                    property: "scale"
                    from: 1
                    to: 0.95
                    duration: Constants.animFast
                    easing.type: Easing.InCubic
                }

            }

            contentItem: ColumnLayout {
                spacing: Constants.sizeXs

                TextField {
                    id: popupSearchInput

                    Layout.fillWidth: true
                    Layout.preferredHeight: Constants.size4Xl
                    leftPadding: Constants.sizeSm
                    rightPadding: Constants.sizeSm
                    visible: root.searchable
                    placeholderText: "Search..."
                    font.pixelSize: Math.round(Constants.sizeSm * SettingsService.fontScale)
                    color: Theme.fg
                    selectionColor: Theme.accent
                    selectedTextColor: Theme.bg
                    onTextEdited: {
                        if (root.searchable) {
                            let query = text.toLowerCase();
                            if (query === "")
                                root._filteredModel = root.model;
                            else
                                root._filteredModel = root.model.filter((item) => {
                                return typeof item === "string" && item.toLowerCase().includes(query);
                            });
                            popupListView.currentIndex = 0;
                        }
                    }
                    Keys.onUpPressed: (event) => {
                        if (popupListView.currentIndex > 0)
                            popupListView.currentIndex--;

                        event.accepted = true;
                    }
                    Keys.onDownPressed: (event) => {
                        if (popupListView.currentIndex < popupListView.count - 1)
                            popupListView.currentIndex++;

                        event.accepted = true;
                    }
                    Keys.onReturnPressed: (event) => {
                        if (popupListView.currentIndex >= 0 && popupListView.currentIndex < root._filteredModel.length) {
                            let selectedItem = root._filteredModel[popupListView.currentIndex];
                            let originalIndex = root.model.indexOf(selectedItem);
                            if (originalIndex !== -1)
                                root.activated(originalIndex);

                            internalCombo.popup.close();
                        }
                        event.accepted = true;
                    }

                    background: Rectangle {
                        color: Theme.bgSecondary
                        radius: Constants.sizeXs
                    }

                }

                ListView {
                    id: popupListView

                    function updateCurrentIndex() {
                        if (root.searchable && root._filteredModel) {
                            let activeStr = root.model[root.currentIndex];
                            let idx = root._filteredModel.indexOf(activeStr);
                            popupListView.currentIndex = idx !== -1 ? idx : 0;
                        } else {
                            popupListView.currentIndex = internalCombo.currentIndex;
                        }
                    }

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: contentHeight
                    clip: true
                    spacing: Constants.size3Xs
                    model: internalCombo.delegateModel

                    ScrollIndicator.vertical: ScrollIndicator {
                    }

                }

            }

            background: Rectangle {
                color: Theme.bg
                border.width: 1
                border.color: Theme.border
                radius: Constants.sizeSm
            }

        }

        delegate: ItemDelegate {
            id: delegateItem

            width: ListView.view.width
            height: 34

            HoverHandler {
                cursorShape: Qt.PointingHandCursor
            }

            background: Rectangle {
                anchors.fill: parent
                radius: Constants.sizeXs
                color: popupListView.currentIndex === index || delegateItem.hovered || delegateItem.down ? Theme.bgSecondary : "transparent"

                Behavior on color {
                    ColorAnimation {
                        duration: Constants.animFast
                    }

                }

            }

            contentItem: RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Constants.sizeMd
                anchors.rightMargin: Constants.sizeMd
                spacing: Constants.sizeXs

                ThemedText {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: {
                        if (typeof modelData !== "string")
                            return "";

                        if (root.textMap && root.textMap[modelData] !== undefined)
                            return root.textMap[modelData];

                        return modelData.split('-').map((word) => {
                            return word.charAt(0).toUpperCase() + word.slice(1);
                        }).join('-');
                    }
                    font.bold: popupListView.currentIndex === index
                    customSize: root.customSize
                    color: popupListView.currentIndex === index || delegateItem.hovered ? Theme.accent : Theme.fg
                    verticalAlignment: Text.AlignVCenter
                }

            }

        }

    }

}
