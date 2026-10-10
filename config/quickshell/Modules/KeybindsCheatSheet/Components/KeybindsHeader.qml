import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components

AppHeader {
    id: headerRoot

    required property var keybindsRoot
    readonly property alias searchField: searchField

    title: keybindsRoot.selectedCategory === "All" ? "All Keybinds" : keybindsRoot.selectedCategory
    category: "HYPRLAND"
    subtitle: keybindsRoot.searchText !== "" ? (keybindsRoot.displayedBinds.length + " shortcuts found") : (keybindsRoot.selectedCategory === "All" ? (keybindsRoot.totalKeybinds + " keybinds configured in system") : (keybindsRoot.categoryBindCount(keybindsRoot.selectedCategory) + " shortcuts in this category"))
    showDivider: true

    Rectangle {
        Layout.preferredWidth: 260
        Layout.preferredHeight: 34
        color: "transparent"
        Layout.alignment: Qt.AlignVCenter

        ThemedSearchBar {
            id: searchField

            anchors.fill: parent
            customSize: Constants.sizeSm
            placeholderText: "Search keybinds (/)..."
            text: keybindsRoot.searchText
            onSearchRequested: (text) => {
                keybindsRoot.searchText = text;
            }
            textField.Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Escape) {
                    if (keybindsRoot.searchText !== "") {
                        keybindsRoot.searchText = "";
                        event.accepted = true;
                    }
                }
            }
        }

    }

}
