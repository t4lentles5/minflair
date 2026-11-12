import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components

AppSidebar {
    id: sidebarRoot

    required property var keybindsRoot

    title: "KEYBINDS"
    subtitle: "HYPRLAND SHORTCUT REFERENCE"

    SidebarSectionLabel {
        text: "CATEGORIES"
    }

    // All Keybinds (Tab)
    SidebarNavItem {
        iconName: "keyboard"
        labelText: "All Keybinds"
        statusText: keybindsRoot.totalKeybinds > 0 ? (keybindsRoot.totalKeybinds + "") : ""
        isActive: keybindsRoot.selectedCategory === "All"
        onRowClicked: keybindsRoot.selectCategory("All")
    }

    Repeater {
        model: keybindsRoot.hyprlandData

        SidebarNavItem {
            iconName: keybindsRoot.categoryIcon(modelData.section)
            labelText: modelData.section
            statusText: modelData.bindCount > 0 ? (modelData.bindCount + "") : ""
            isActive: keybindsRoot.selectedCategory === modelData.section
            onRowClicked: keybindsRoot.selectCategory(modelData.section)
        }

    }

    Item {
        Layout.preferredHeight: Constants.sizeMd
    }

}
