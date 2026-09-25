import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Components

ColumnLayout {
    // searchField moved to parent
    // ThemedSearchBar moved to parent

    id: rightFlick

    property var currentBinds: []
    property var groupedBinds: {
        let groups = [];
        let currentGroup = null;
        for (let i = 0; i < currentBinds.length; i++) {
            let item = currentBinds[i];
            if (item.is_subheader) {
                if (currentGroup !== null && currentGroup.binds.length > 0)
                    groups.push(currentGroup);

                currentGroup = {
                    "name": item.name,
                    "binds": []
                };
            } else {
                if (currentGroup === null)
                    currentGroup = {
                    "name": "General",
                    "binds": []
                };

                currentGroup.binds.push(item);
            }
        }
        if (currentGroup !== null && currentGroup.binds.length > 0)
            groups.push(currentGroup);

        return groups;
    }

    signal searchRequested(string text)

    function focusSearch() {
    }

    spacing: 0

    AppContainer {
        Layout.fillWidth: true
        Layout.fillHeight: true
        contentPadding: 0

        Repeater {
            model: rightFlick.groupedBinds

            AppGroup {
                title: modelData.name || "General"
                icon: "keyboard"

                Repeater {
                    model: modelData.binds

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Constants.sizeLg

                        KeybindItem {
                            uiElements: modelData.uiElements || []
                            desc: modelData.desc || ""
                        }

                    }

                }

            }

        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 300
            visible: currentBinds.length === 0

            GhostEmptyState {
                anchors.centerIn: parent
                text: "No keybinds loaded"
                isAnimating: currentBinds.length === 0
            }

        }

    }

}
