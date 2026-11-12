import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Core
import qs.Core.Components
import qs.Core.Services

AppSidebar {
    id: sidebarRoot

    property int activeTab: 0

    signal tabClicked(int index)

    title: "SETTINGS"
    subtitle: "PREFERENCES & CUSTOMIZATION"

    // Section 1: DESKTOP
    SidebarSectionLabel {
        text: "DESKTOP"
    }

    // Appearance (Tab 0)
    SidebarNavItem {
        iconName: "color-palette"
        labelText: "Appearance"
        isActive: sidebarRoot.activeTab === 0
        onRowClicked: sidebarRoot.tabClicked(0)
    }

    // Wallpaper (Tab 8)
    SidebarNavItem {
        iconName: "picture"
        labelText: "Wallpaper"
        isActive: sidebarRoot.activeTab === 8
        onRowClicked: sidebarRoot.tabClicked(8)
    }

    // Desktop Bar (Tab 1)
    SidebarNavItem {
        iconName: "bar"
        labelText: "Desktop Bar"
        isActive: sidebarRoot.activeTab === 1
        onRowClicked: sidebarRoot.tabClicked(1)
    }

    // Visual Effects (Tab 2)
    SidebarNavItem {
        iconName: "sparkles"
        labelText: "Visual Effects"
        isActive: sidebarRoot.activeTab === 2
        onRowClicked: sidebarRoot.tabClicked(2)
    }

    // Windows & Display (Tab 3)
    SidebarNavItem {
        iconName: "monitor"
        labelText: "Windows & Display"
        isActive: sidebarRoot.activeTab === 3
        onRowClicked: sidebarRoot.tabClicked(3)
    }

    // Section 2: INPUT & HARDWARE
    SidebarSectionLabel {
        text: "INPUT & HARDWARE"
        sectionTopMargin: Constants.sizeSm
    }

    // Mouse & Touchpad (Tab 5)
    SidebarNavItem {
        iconName: "cursor"
        labelText: "Mouse & Touchpad"
        isActive: sidebarRoot.activeTab === 5
        onRowClicked: sidebarRoot.tabClicked(5)
    }

    // Keyboard & Clipboard (Tab 6)
    SidebarNavItem {
        iconName: "keyboard"
        labelText: "Keyboard & Clipboard"
        isActive: sidebarRoot.activeTab === 6
        onRowClicked: sidebarRoot.tabClicked(6)
    }

    // Section 3: MANAGEMENT
    SidebarSectionLabel {
        text: "MANAGEMENT"
        sectionTopMargin: Constants.sizeSm
    }

    // Integrations & Apps (Tab 4)
    SidebarNavItem {
        iconName: "apps"
        labelText: "Integrations & Apps"
        isActive: sidebarRoot.activeTab === 4
        onRowClicked: sidebarRoot.tabClicked(4)
    }

    // Section 4: ABOUT
    SidebarSectionLabel {
        text: "ABOUT"
        sectionTopMargin: Constants.sizeSm
    }

    // About System (Tab 7 - System Info)
    SidebarNavItem {
        iconName: "info"
        labelText: "About System"
        isActive: sidebarRoot.activeTab === 7
        onRowClicked: sidebarRoot.tabClicked(7)
    }

    Item {
        Layout.preferredHeight: Constants.sizeMd
    }

}
