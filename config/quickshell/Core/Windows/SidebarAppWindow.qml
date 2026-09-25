import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components

AppWindow {
    id: root

    property alias sidebarModel: sidebar.fullModel
    property int activeTab: 0
    property alias sidebar: sidebar
    default property alias content: contentLayout.data
    property bool useSameIconForActive: false

    signal tabClicked(int tabIndex)

    contentPadding: 0

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 0

        IconSidebar {
            id: sidebar

            useSameIconForActive: root.useSameIconForActive
            Layout.fillHeight: true
            activeId: root.activeTab
            onTabClicked: (id) => {
                root.tabClicked(id);
            }
        }

        Item {
            id: contentLayout

            Layout.fillWidth: true
            Layout.fillHeight: true
        }

    }

    Shortcut {
        sequence: "Ctrl+Tab"
        enabled: root.isOpen && root.sidebarModel && root.sidebarModel.length > 1
        onActivated: {
            let nextTab = (root.activeTab + 1) % root.sidebarModel.length;
            root.tabClicked(nextTab);
        }
    }

    Shortcut {
        sequence: "Ctrl+Shift+Tab"
        enabled: root.isOpen && root.sidebarModel && root.sidebarModel.length > 1
        onActivated: {
            let nextTab = (root.activeTab - 1 + root.sidebarModel.length) % root.sidebarModel.length;
            root.tabClicked(nextTab);
        }
    }

}
