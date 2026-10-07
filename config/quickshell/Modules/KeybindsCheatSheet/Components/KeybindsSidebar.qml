import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components

AppSidebar {
    id: sidebarRoot

    required property var keybindsRoot

    title: "KEYBINDS"
    subtitle: (keybindsRoot.totalKeybinds > 0 ? (keybindsRoot.totalKeybinds + " SHORTCUTS") : "HYPRLAND") + " / CHEATSHEET"

    ThemedText {
        text: "CATEGORIES"
        customSize: 10
        font.weight: Font.Bold
        font.letterSpacing: 0.8
        color: Theme.muted
        Layout.leftMargin: Constants.sizeLg
        Layout.topMargin: Constants.size2Xs
        Layout.bottomMargin: Constants.size2Xs
    }

    // All Keybinds (Tab)
    Item {
        Layout.fillWidth: true
        Layout.leftMargin: Constants.sizeSm
        Layout.rightMargin: Constants.sizeSm
        Layout.preferredHeight: 34

        SidebarNavRow {
            anchors.fill: parent
            iconName: "keyboard"
            labelText: "All Keybinds"
            statusText: keybindsRoot.totalKeybinds > 0 ? (keybindsRoot.totalKeybinds + "") : ""
            isActive: keybindsRoot.selectedCategory === "All"
            onRowClicked: keybindsRoot.selectCategory("All")
        }

    }

    Repeater {
        model: keybindsRoot.hyprlandData

        Item {
            Layout.fillWidth: true
            Layout.leftMargin: Constants.sizeSm
            Layout.rightMargin: Constants.sizeSm
            Layout.preferredHeight: 34

            SidebarNavRow {
                anchors.fill: parent
                iconName: keybindsRoot.categoryIcon(modelData.section)
                labelText: modelData.section
                statusText: modelData.bindCount > 0 ? (modelData.bindCount + "") : ""
                isActive: keybindsRoot.selectedCategory === modelData.section
                onRowClicked: keybindsRoot.selectCategory(modelData.section)
            }

        }

    }

    Item {
        Layout.preferredHeight: Constants.sizeMd
    }

}
