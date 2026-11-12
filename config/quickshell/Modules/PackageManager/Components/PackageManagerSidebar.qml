import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services

AppSidebar {
    id: sidebarRoot

    required property var managerRoot

    title: "PACKAGES"
    subtitle: "SOFTWARE & SYSTEM UPDATES"

    SidebarSectionLabel {
        text: "MODES"
    }

    // Mode 1: Discover
    SidebarNavItem {
        iconName: "rocket"
        labelText: "Discover"
        statusText: ""
        isActive: managerRoot.actionMode === "install"
        onRowClicked: managerRoot.switchMode("install")
    }

    // Mode 2: Installed
    SidebarNavItem {
        iconName: "box"
        labelText: "Installed"
        statusText: managerRoot.actionMode === "remove" && managerRoot.resultsModel.count > 0 ? (managerRoot.resultsModel.count + "") : ""
        isActive: managerRoot.actionMode === "remove"
        onRowClicked: managerRoot.switchMode("remove")
    }

    // Mode 3: Updates
    SidebarNavItem {
        iconName: "update"
        labelText: "Updates"
        statusText: {
            if (managerRoot.actionMode === "update" && managerRoot.allResults.length > 0)
                return managerRoot.allResults.length + "";

            return "";
        }
        isActive: managerRoot.actionMode === "update"
        onRowClicked: managerRoot.switchMode("update")
    }

    // Categories Section (Featured for Discover Mode)
    SidebarSectionLabel {
        visible: managerRoot.actionMode === "install"
        text: "FEATURED"
        sectionTopMargin: Constants.sizeMd
    }

    Repeater {
        model: managerRoot.actionMode === "install" ? [{
            "label": "All Featured",
            "val": "featured",
            "icon": "sparkles"
        }, {
            "label": "Internet",
            "val": "internet",
            "icon": "wifi"
        }, {
            "label": "Development",
            "val": "development",
            "icon": "code"
        }, {
            "label": "Multimedia",
            "val": "multimedia",
            "icon": "music"
        }, {
            "label": "Gaming",
            "val": "gaming",
            "icon": "gamepad"
        }, {
            "label": "Utilities",
            "val": "utilities",
            "icon": "tune"
        }, {
            "label": "Office",
            "val": "office",
            "icon": "clipboard"
        }] : []

        SidebarNavItem {
            iconName: modelData.icon
            labelText: modelData.label
            isActive: managerRoot.selectedCategory === modelData.val && managerRoot.searchText === ""
            onRowClicked: managerRoot.switchCategory(modelData.val)
        }

    }

    Item {
        Layout.preferredHeight: Constants.sizeMd
    }

}
