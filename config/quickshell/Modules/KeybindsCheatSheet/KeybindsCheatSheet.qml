import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Core
import qs.Core.Components
import qs.Core.Windows
import qs.Modules.KeybindsCheatSheet.Components

SearchAppWindow {
    id: root

    property var hyprlandData: []
    property string searchText: ""
    property string selectedCategory: "All"
    property var categories: {
        let cats = ["All"];
        for (let i = 0; i < hyprlandData.length; i++) {
            if (cats.indexOf(hyprlandData[i].section) === -1)
                cats.push(hyprlandData[i].section);

        }
        return cats;
    }
    property int totalKeybinds: {
        let count = 0;
        for (let i = 0; i < hyprlandData.length; i++) {
            count += hyprlandData[i].bindCount || 0;
        }
        return count;
    }
    property var computedBinds: {
        if (hyprlandData.length === 0)
            return [];

        let matches = [];
        let lowerSearch = searchText.toLowerCase();
        for (let i = 0; i < hyprlandData.length; i++) {
            let cat = hyprlandData[i];
            if (selectedCategory !== "All" && cat.section !== selectedCategory)
                continue;

            let hasAddedHeader = false;
            for (let j = 0; j < cat.binds.length; j++) {
                let bind = cat.binds[j];
                if (searchText !== "") {
                    if (bind.is_subheader)
                        continue;

                    let matchDesc = bind.desc && bind.desc.toLowerCase().indexOf(lowerSearch) !== -1;
                    let matchKey = false;
                    for (let k = 0; k < bind.uiElements.length; k++) {
                        if (bind.uiElements[k].isKey && bind.uiElements[k].text.toLowerCase().indexOf(lowerSearch) !== -1) {
                            matchKey = true;
                            break;
                        }
                    }
                    if (matchDesc || matchKey) {
                        if (!hasAddedHeader) {
                            matches.push({
                                "is_subheader": true,
                                "name": cat.section,
                                "uiElements": [],
                                "desc": ""
                            });
                            hasAddedHeader = true;
                        }
                        matches.push(bind);
                    }
                } else {
                    if (bind.is_subheader)
                        matches.push({
                        "is_subheader": true,
                        "name": bind.name,
                        "uiElements": [],
                        "desc": ""
                    });
                    else
                        matches.push(bind);
                }
            }
        }
        return matches;
    }
    property var displayedBinds: []

    function loadKeybinds() {
        hyprlandData = [];
        hyprProc.running = true;
    }

    function processKeybindData(rawData) {
        let processed = [];
        for (let i = 0; i < rawData.length; i++) {
            let section = rawData[i];
            let newBinds = [];
            let bindCount = 0;
            for (let j = 0; j < section.binds.length; j++) {
                let bind = section.binds[j];
                if (bind.is_subheader) {
                    newBinds.push({
                        "is_subheader": true,
                        "name": bind.name,
                        "uiElements": [],
                        "desc": ""
                    });
                    continue;
                }
                bindCount++;
                let keys = bind.keys;
                let desc = bind.desc;
                let result = [];
                let multiKeys = [];
                let joiner = "";
                if (desc.endsWith(" ←→↑↓")) {
                    desc = desc.replace(" ←→↑↓", "");
                    multiKeys = ["↕ ↔"];
                } else if (desc.endsWith(" 1..0")) {
                    desc = desc.replace(" 1..0", "");
                    multiKeys = ["1", "0"];
                    joiner = "..";
                } else if (desc === "Previous / Next Workspace") {
                    multiKeys = ["←", "→"];
                    joiner = "/";
                } else if (desc === "Scroll Through Workspaces") {
                    multiKeys = ["Scroll ↓", "Scroll ↑"];
                    joiner = "/";
                } else {
                    multiKeys = [keys[keys.length - 1]];
                }
                for (let k = 0; k < keys.length - 1; k++) {
                    result.push({
                        "text": keys[k],
                        "isKey": true
                    });
                    result.push({
                        "text": "+",
                        "isKey": false
                    });
                }
                for (let k = 0; k < multiKeys.length; k++) {
                    result.push({
                        "text": multiKeys[k],
                        "isKey": true
                    });
                    if (k < multiKeys.length - 1 && joiner !== "")
                        result.push({
                        "text": joiner,
                        "isKey": false
                    });

                }
                newBinds.push({
                    "uiElements": result,
                    "desc": desc
                });
            }
            processed.push({
                "section": section.section,
                "binds": newBinds,
                "bindCount": bindCount
            });
        }
        return processed;
    }

    onComputedBindsChanged: {
        root.displayedBinds = root.computedBinds;
    }
    popupId: "minflair_keybinds"
    windowTitle: "Minflair Keybinds Cheat Sheet"
    placeholderText: "Search keybinds..."
    tabsModel: root.categories
    activeTabValue: root.selectedCategory
    onSearchRequested: (text) => {
        root.searchText = text;
    }
    onTabClicked: (val, index) => {
        root.selectedCategory = val;
    }
    onIsOpenChanged: {
        if (isOpen)
            root.loadKeybinds();

    }
    onWindowReadyForFocus: {
        root.focusSearch();
    }

    Shortcut {
        sequence: "Ctrl+Tab"
        onActivated: {
            let cats = root.categories;
            if (cats.length === 0)
                return ;

            let idx = cats.indexOf(root.selectedCategory);
            if (idx === -1)
                idx = 0;

            let nextIdx = (idx + 1) % cats.length;
            root.selectedCategory = cats[nextIdx];
            root.activeTabIndex = nextIdx;
        }
    }

    Shortcut {
        sequence: "Ctrl+Shift+Tab"
        onActivated: {
            let cats = root.categories;
            if (cats.length === 0)
                return ;

            let idx = cats.indexOf(root.selectedCategory);
            if (idx === -1)
                idx = 0;

            let prevIdx = (idx - 1 + cats.length) % cats.length;
            root.selectedCategory = cats[prevIdx];
            root.activeTabIndex = prevIdx;
        }
    }

    Process {
        id: hyprProc

        command: ["python3", Quickshell.shellDir + "/Scripts/parse_keybinds.py"]
        onExited: function(exitCode) {
            if (exitCode === 0) {
                try {
                    let rawData = JSON.parse(hyprOutput.text);
                    root.hyprlandData = processKeybindData(rawData);
                } catch (e) {
                    console.error("Error parsing Hyprland keybinds: " + e);
                }
            }
        }

        stdout: StdioCollector {
            id: hyprOutput
        }

    }

    KeybindsList {
        id: bindsList

        anchors.fill: parent
        currentBinds: root.displayedBinds
    }

}
