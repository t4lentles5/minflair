import QtQml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Widgets
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Core.Utils
import qs.Modules.Launcher.Components

Item {
    id: root

    property var widget: null
    property string searchText: ""
    property var allApps: []
    property var results: []
    property alias initialFocusItem: searchField
    property int maxVisibleItems: 7
    readonly property bool isSearching: searchField.text.trim() !== ""
    readonly property string emptyStateText: {
        let engine = engineForQuery(searchField.text);
        if (engine)
            return "Type what to search on " + engine.name;

        return "No results found";
    }
    readonly property int currentResultsCount: root.results ? root.results.length : 0
    readonly property var searchEngines: [{
        "prefix": "g",
        "name": "Google",
        "url": "https://www.google.com/search?q="
    }, {
        "prefix": "yt",
        "name": "YouTube",
        "url": "https://www.youtube.com/results?search_query="
    }, {
        "prefix": "w",
        "name": "Wikipedia",
        "url": "https://en.wikipedia.org/w/index.php?search="
    }, {
        "prefix": "gh",
        "name": "GitHub",
        "url": "https://github.com/search?q="
    }, {
        "prefix": "ddg",
        "name": "DuckDuckGo",
        "url": "https://duckduckgo.com/?q="
    }]
    readonly property int targetVisibleItems: {
        if (!isSearching)
            return maxVisibleItems;

        if (currentResultsCount === 0)
            return maxVisibleItems;

        return Math.min(currentResultsCount, maxVisibleItems);
    }
    property int visibleItems: targetVisibleItems
    property int preferredContentWidth: 640
    readonly property int searchBarHeight: Constants.size4Xl
    readonly property int itemHeight: 44
    readonly property int listSpacing: Constants.sizeXs
    readonly property int layoutSpacing: Constants.sizeSm
    readonly property int maxListHeight: (maxVisibleItems * itemHeight) + Math.max(0, (maxVisibleItems - 1) * listSpacing)
    readonly property int baseListHeight: (targetVisibleItems * itemHeight) + Math.max(0, (targetVisibleItems - 1) * listSpacing)
    readonly property int expandedExtraHeight: {
        if (typeof appsView !== "undefined" && appsView && appsView.expandedIndex >= 0 && root.results && appsView.expandedIndex < root.results.length) {
            let app = root.results[appsView.expandedIndex];
            if (app && app.actions && app.actions.length > 0) {
                let n = app.actions.length;
                return (n * 34) + Math.max(0, (n - 1) * 4) + Constants.sizeXs;
            }
        }
        return 0;
    }
    readonly property int visibleListHeight: {
        if (!isSearching)
            return maxListHeight + Math.min(expandedExtraHeight, 200);

        if (currentResultsCount === 0)
            return maxListHeight;

        let needed = baseListHeight + expandedExtraHeight;
        let maxAllowed = maxListHeight + Math.min(expandedExtraHeight, 200);
        return Math.min(needed, maxAllowed);
    }

    function isMinflairShortcut(app) {
        return app && app.exec && app.exec.indexOf("open_minflair_") !== -1;
    }

    function appEntry(app) {
        return {
            "type": "app",
            "name": app.name,
            "exec": app.exec,
            "icon": app.icon,
            "terminal": app.terminal,
            "actions": app.actions || []
        };
    }

    function matchingApps(query) {
        let out = [];
        let needle = query.toLowerCase();
        for (let i = 0; i < root.allApps.length; i++) {
            let app = root.allApps[i];
            if (isMinflairShortcut(app))
                continue;

            if (needle !== "" && app.name.toLowerCase().indexOf(needle) === -1)
                continue;

            out.push(appEntry(app));
        }
        return out;
    }

    function matchingCommands(query) {
        let out = [];
        let needle = query.toLowerCase();
        let list = launcherCommands.items;
        for (let i = 0; i < list.length; i++) {
            let command = list[i];
            let matched = command.name.toLowerCase().indexOf(needle) !== -1;
            if (!matched) {
                for (let k = 0; k < command.keywords.length; k++) {
                    if (command.keywords[k].indexOf(needle) !== -1) {
                        matched = true;
                        break;
                    }
                }
            }
            if (matched)
                out.push({
                "type": "command",
                "name": command.name,
                "subtitle": command.subtitle,
                "widgetId": command.widgetId
            });

        }
        return out;
    }

    function webResult(term, engine) {
        if (!term || term.length === 0)
            return null;

        return {
            "type": "search",
            "name": term,
            "subtitle": engine.name,
            "url": engine.url + encodeURIComponent(term)
        };
    }

    function findEngine(token) {
        let needle = token.toLowerCase();
        for (let i = 0; i < root.searchEngines.length; i++) {
            if (root.searchEngines[i].prefix === needle)
                return root.searchEngines[i];

        }
        return null;
    }

    // A search engine only kicks in once a space follows the prefix, so plain
    // app searches like "w" keep working.
    function engineForQuery(query) {
        let parts = String(query).replace(/^\s+/, "").split(/\s+/);
        if (parts.length < 2)
            return null;

        return findEngine(parts[0]);
    }

    function buildResults(query) {
        let text = query.trim();
        let out = [];
        if (text === "") {
            out = matchingApps("");
        } else if (text.startsWith(">")) {
            // Command mode: Minflair applications first, then anything else
            // is offered as a shell command for kitty.
            let term = text.substring(1).trim();
            out = matchingCommands(term);
            if (out.length === 0 && term.length > 0)
                out.push({
                "type": "run",
                "name": term,
                "subtitle": "Run in kitty",
                "command": term
            });

        } else {
            // Calculator: only real expressions, never a bare number.
            if (MathEval.isExpression(text)) {
                let formatted = MathEval.format(MathEval.evaluate(text));
                if (formatted !== "")
                    out.push({
                    "type": "calculator",
                    "name": text + " = " + formatted,
                    "subtitle": "Copy result",
                    "value": formatted
                });

            }
            // Web search only through an explicit prefix (g, yt, w, gh, ddg).
            let engine = engineForQuery(query);
            if (engine) {
                let parts = query.replace(/^\s+/, "").split(/\s+/);
                let search = webResult(parts.slice(1).join(" ").trim(), engine);
                if (search)
                    out.push(search);

            } else {
                out = out.concat(matchingApps(text));
            }
        }
        root.results = out;
        if (appsView) {
            appsView.expandedIndex = -1;
            appsView.currentIndex = root.results.length > 0 ? 0 : -1;
        }
    }

    function closeLauncher() {
        AppState.closeAllWidgets();
        if (root.widget && typeof root.widget.close === "function")
            root.widget.close();
        else if (root.widget && root.widget.isOpen !== undefined)
            root.widget.isOpen = false;
    }

    function shellQuote(text) {
        return "'" + String(text).replace(/'/g, "'\\''") + "'";
    }

    // Launch through the compositor, exactly like the Hyprland keybinds do.
    // A child started by the shell itself can die together with the closing
    // window, which is why terminal apps never showed up before.
    function launchShell(command) {
        if (!command)
            return ;

        let request = Hyprland.usingLua ? "hl.dsp.exec_cmd(" + JSON.stringify(command) + ")" : "exec " + command;
        Hyprland.dispatch(request);
    }

    function launchApp(exec, terminal) {
        if (!exec)
            return ;

        let command = String(exec).trim();
        if (terminal)
            command = "kitty -e " + command;

        closeLauncher();
        launchShell(command);
    }

    function copyToClipboard(text) {
        clipboardCopier.command = ["wl-copy", "--", text];
        clipboardCopier.startDetached();
    }

    function browserExec() {
        let list = SettingsService.availableBrowsers || [];
        let selected = SettingsService.launcherBrowser;
        if (!selected)
            return "";

        for (let i = 0; i < list.length; i++) {
            if (list[i].id === selected)
                return list[i].exec;

        }
        return "";
    }

    function openUrl(url) {
        if (!url)
            return ;

        let quoted = shellQuote(url);
        let exec = browserExec();
        if (!exec) {
            launchShell("xdg-open " + quoted);
            return ;
        }
        let command = exec;
        if (/%[uU]/.test(command))
            command = command.replace(/%[uU]/g, quoted);
        else
            command = command + " " + quoted;
        // Drop any other field code the desktop entry may carry (%f, %i...).
        command = command.replace(/%[a-zA-Z]/g, "").trim();
        launchShell(command);
    }

    function activateResult(index) {
        if (index < 0 || index >= root.results.length)
            return ;

        let item = root.results[index];
        if (item.type === "calculator") {
            copyToClipboard(item.value);
            closeLauncher();
        } else if (item.type === "command") {
            closeLauncher();
            AppState.openWidget(item.widgetId);
        } else if (item.type === "search") {
            closeLauncher();
            openUrl(item.url);
        } else if (item.type === "run") {
            closeLauncher();
            launchShell("kitty --hold -e sh -c " + shellQuote(item.command));
        } else {
            launchApp(item.exec, item.terminal);
        }
    }

    function handleKeyPress(event, fromSearch) {
        let currentDelegate = appsView.currentItem;
        if (event.key === Qt.Key_Down) {
            if (currentDelegate && currentDelegate.isExpanded && currentDelegate.currentActionIndex < currentDelegate.actionCount - 1) {
                currentDelegate.currentActionIndex++;
                event.accepted = true;
            } else if (appsView.count > 0) {
                appsView.expandedIndex = -1;
                appsView.currentIndex = Math.min(appsView.count - 1, appsView.currentIndex + 1);
                event.accepted = true;
            }
        } else if (event.key === Qt.Key_Up) {
            if (currentDelegate && currentDelegate.isExpanded && currentDelegate.currentActionIndex >= 0) {
                currentDelegate.currentActionIndex--;
                event.accepted = true;
            } else if (appsView.count > 0) {
                appsView.expandedIndex = -1;
                appsView.currentIndex = Math.max(0, appsView.currentIndex - 1);
                event.accepted = true;
            }
        } else if (event.key === Qt.Key_Right) {
            if (currentDelegate && currentDelegate.hasActions && !currentDelegate.isExpanded) {
                appsView.expandedIndex = appsView.currentIndex;
                currentDelegate.currentActionIndex = 0;
                event.accepted = true;
            }
        } else if (event.key === Qt.Key_Left) {
            if (currentDelegate && currentDelegate.isExpanded) {
                appsView.expandedIndex = -1;
                event.accepted = true;
            }
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            let idx = appsView.currentIndex >= 0 ? appsView.currentIndex : 0;
            if (root.results.length > idx) {
                if (currentDelegate && currentDelegate.isExpanded && currentDelegate.currentActionIndex >= 0) {
                    let action = root.results[idx].actions[currentDelegate.currentActionIndex];
                    launchApp(action.exec, false);
                } else {
                    activateResult(idx);
                }
                event.accepted = true;
            }
        } else if (event.key === Qt.Key_Escape) {
            closeLauncher();
            event.accepted = true;
        }
    }

    function resetLauncher() {
        if (appsView)
            appsView.expandedIndex = -1;

        searchField.text = "";
        if (AppState.launcherApps && AppState.launcherApps.length > 0) {
            root.allApps = AppState.launcherApps;
            buildResults("");
        } else {
            loadAppsProc.running = true;
        }
        searchField.forceActiveFocus();
    }

    implicitWidth: preferredContentWidth
    implicitHeight: searchBarHeight + layoutSpacing + visibleListHeight
    width: parent && parent.width > 0 ? parent.width : implicitWidth
    height: parent && parent.height > 0 ? parent.height : implicitHeight
    Component.onCompleted: {
        resetLauncher();
    }

    Process {
        id: loadAppsProc

        command: ["python3", Quickshell.shellDir + "/Modules/Launcher/scripts/get_apps.py"]
        onExited: function(exitCode) {
            if (exitCode === 0) {
                try {
                    let parsed = JSON.parse(appFetcherOutput.text);
                    AppState.launcherApps = parsed;
                    root.allApps = parsed;
                    buildResults(searchField.text);
                } catch (e) {
                    console.error("Error parsing apps JSON: " + e);
                }
            }
        }

        stdout: StdioCollector {
            id: appFetcherOutput
        }

    }

    ColumnLayout {
        anchors.fill: parent
        spacing: root.layoutSpacing

        Item {
            id: topSearchContainer

            Layout.fillWidth: true
            Layout.preferredHeight: SettingsService.barConvexMode ? 0 : Constants.size4Xl
            visible: !SettingsService.barConvexMode
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: root.visibleListHeight
            clip: true

            GhostEmptyState {
                anchors.centerIn: parent
                visible: opacity > 0.001
                opacity: (root.results.length === 0 && root.isSearching) ? 1 : 0
                text: root.emptyStateText
                isAnimating: visible

                Behavior on opacity {
                    NumberAnimation {
                        duration: Constants.animFast
                        easing.type: Easing.OutCubic
                    }

                }

            }

            ListView {
                id: appsView

                property int expandedIndex: -1

                onExpandedIndexChanged: {
                    if (expandedIndex >= 0)
                        Qt.callLater(function() {
                        appsView.positionViewAtIndex(expandedIndex, ListView.Contain);
                    });

                }
                anchors.fill: parent
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: root.results
                spacing: root.listSpacing
                currentIndex: -1
                highlightResizeDuration: 0
                highlightMoveDuration: Constants.animFast
                highlightFollowsCurrentItem: true
                visible: root.results.length > 0
                Keys.onPressed: function(event) {
                    root.handleKeyPress(event, false);
                }

                highlight: Item {
                    width: appsView.width
                    height: 44
                    z: 1

                    Rectangle {
                        anchors.fill: parent
                        radius: Constants.sizeLg
                        color: Theme.bgSecondary
                    }

                }

                add: Transition {
                    NumberAnimation {
                        properties: "opacity"
                        from: 0
                        to: 1
                        duration: root.isSearching ? 0 : Constants.animFast
                        easing.type: Easing.OutQuint
                    }

                }

                populate: Transition {
                    NumberAnimation {
                        properties: "opacity"
                        from: 0
                        to: 1
                        duration: root.isSearching ? 0 : Constants.animFast
                        easing.type: Easing.OutQuint
                    }

                }

                delegate: LauncherItemDelegate {
                    modelData: model.modelData
                    isCurrent: appsView.currentIndex === index
                    isExpanded: appsView.expandedIndex === index
                    onToggleExpanded: {
                        if (appsView.expandedIndex === index) {
                            appsView.expandedIndex = -1;
                        } else {
                            appsView.expandedIndex = index;
                            appsView.currentIndex = index;
                        }
                    }
                    onLaunchRequested: function(execCmd, terminalFlag) {
                        root.launchApp(execCmd, terminalFlag);
                    }
                    onActivateRequested: {
                        root.activateResult(index);
                    }
                }

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AlwaysOff
                    active: true
                }

            }

        }

        Item {
            id: bottomSearchContainer

            Layout.fillWidth: true
            Layout.preferredHeight: SettingsService.barConvexMode ? 40 : 0
            visible: SettingsService.barConvexMode
        }

    }

    ThemedSearchBar {
        id: searchField

        parent: SettingsService.barConvexMode ? bottomSearchContainer : topSearchContainer
        anchors.fill: parent
        preferredHeight: Constants.size4Xl
        placeholderText: "Search apps, > commands or math..."
        onSearchRequested: (text) => {
            return root.buildResults(text);
        }
        textField.Keys.onPressed: function(event) {
            root.handleKeyPress(event, true);
        }
    }

    Process {
        id: clipboardCopier
    }

    LauncherCommands {
        id: launcherCommands
    }

}
