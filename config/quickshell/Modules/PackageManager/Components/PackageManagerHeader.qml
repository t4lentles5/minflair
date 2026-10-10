import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components

AppHeader {
    id: headerRoot

    required property var managerRoot
    property var contentComp: null
    readonly property alias searchField: searchField

    title: {
        if (managerRoot.actionMode === "install")
            return managerRoot.selectedCategory === "featured" ? "Discover Packages" : (managerRoot.selectedCategory.charAt(0).toUpperCase() + managerRoot.selectedCategory.slice(1));

        if (managerRoot.actionMode === "remove")
            return "Installed Packages";

        return "System Updates";
    }
    category: "PACMAN & AUR"
    subtitle: {
        if (managerRoot.isSearching)
            return "Searching packages...";

        if (managerRoot.actionMode === "update")
            return managerRoot.allResults.length > 0 ? (managerRoot.allResults.length + " updates available") : "All packages up to date";

        if (managerRoot.searchText.length > 0)
            return managerRoot.resultsModel.count + " packages found";

        if (managerRoot.actionMode === "remove")
            return managerRoot.resultsModel.count + " packages installed";

        return "Curated software and community repositories";
    }
    showDivider: true

    Rectangle {
        visible: managerRoot.actionMode !== "update"
        Layout.preferredWidth: 260
        Layout.preferredHeight: 34
        color: "transparent"
        Layout.alignment: Qt.AlignVCenter

        ThemedSearchBar {
            id: searchField

            anchors.fill: parent
            customSize: Constants.sizeSm
            placeholderText: managerRoot.actionMode === "remove" ? "Search installed (/)..." : "Search to install (/)..."
            text: managerRoot.searchText
            onSearchRequested: (text) => {
                managerRoot.searchText = text;
                managerRoot.stopSearchTimers();
                managerRoot.restartDebounceTimer();
            }
            textField.onTextChanged: {
                if (searchField.textField.text.length > 0 && !searchField.textField.activeFocus)
                    searchField.textField.forceActiveFocus();

            }
            textField.Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Escape) {
                    if (managerRoot.searchText !== "") {
                        managerRoot.searchText = "";
                        event.accepted = true;
                        return ;
                    }
                    if (headerRoot.contentComp)
                        headerRoot.contentComp.focusListView();
                    else
                        searchField.textField.focus = false;
                    event.accepted = true;
                    return ;
                }
                managerRoot.handleKeyPress(event, true);
            }
        }

    }

}
