import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Core
import qs.Core.Components
import qs.Core.Windows
import qs.Modules.KeybindsCheatSheet.Components

AppWindow {
    id: root

    property var hyprlandData: []
    property string searchText: ""
    property string selectedCategory: "All"
    readonly property alias searchField: keybindsHeader.searchField
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

    function selectCategory(cat) {
        if (root.selectedCategory === cat)
            return ;

        let prevIdx = root.categories.indexOf(root.selectedCategory);
        let nextIdx = root.categories.indexOf(cat);
        let dir = (prevIdx !== -1 && nextIdx !== -1) ? (nextIdx > prevIdx ? 1 : -1) : 1;
        if (typeof pageTransition !== "undefined" && pageTransition)
            pageTransition.triggerTransition(dir, function() {
            root.selectedCategory = cat;
        });
        else
            root.selectedCategory = cat;
    }

    function categoryBindCount(catName) {
        for (let i = 0; i < hyprlandData.length; i++) {
            if (hyprlandData[i].section === catName)
                return hyprlandData[i].bindCount || 0;

        }
        return 0;
    }

    function categoryIcon(sectionName) {
        let s = (sectionName || "").toLowerCase();
        if (s.indexOf("workspace") !== -1)
            return "apps";

        if (s.indexOf("window") !== -1)
            return "window";

        if (s.indexOf("app") !== -1 || s.indexOf("launcher") !== -1)
            return "rocket";

        if (s.indexOf("media") !== -1 || s.indexOf("audio") !== -1 || s.indexOf("music") !== -1)
            return "music";

        if (s.indexOf("volume") !== -1)
            return "volume";

        if (s.indexOf("system") !== -1 || s.indexOf("session") !== -1 || s.indexOf("power") !== -1)
            return "power";

        if (s.indexOf("mouse") !== -1 || s.indexOf("touchpad") !== -1)
            return "cursor";

        if (s.indexOf("capture") !== -1 || s.indexOf("screen") !== -1)
            return "capture";

        if (s.indexOf("clipboard") !== -1)
            return "clipboard";

        if (s.indexOf("special") !== -1 || s.indexOf("utility") !== -1)
            return "sparkles";

        return "keyboard";
    }

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
    widgetId: "minflair_keybinds"
    windowTitle: "Minflair Keybinds Cheat Sheet"
    contentPadding: 0
    onIsOpenChanged: {
        if (isOpen)
            root.loadKeybinds();

    }
    onWindowReadyForFocus: {
        searchField.textField.forceActiveFocus();
    }

    Shortcut {
        sequence: "/"
        onActivated: {
            if (!searchField.textField.activeFocus) {
                searchField.textField.forceActiveFocus();
                searchField.textField.selectAll();
            }
        }
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
            root.selectCategory(cats[nextIdx]);
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
            root.selectCategory(cats[prevIdx]);
        }
    }

    Process {
        id: hyprProc

        command: ["python3", Quickshell.shellDir + "/Modules/KeybindsCheatSheet/scripts/parse_keybinds.py"]
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

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 0

        KeybindsSidebar {
            id: sidebar

            keybindsRoot: root
        }

        // Content Area
        ColumnLayout {
            id: contentContainer

            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            KeybindsHeader {
                id: keybindsHeader

                keybindsRoot: root
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: Constants.sizeLg

                PageTransitionView {
                    id: pageTransition

                    anchors.fill: parent

                    KeybindsList {
                        id: bindsList

                        anchors.fill: parent
                        currentBinds: root.displayedBinds
                    }

                }

            }

        }

    }

}
