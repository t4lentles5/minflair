import QtQml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Core.Utils
import qs.Core.Windows
import qs.Modules.PackageManager.Components

SearchAppWindow {
    id: root

    property string searchText: ""
    property var allResults: []
    property string installingPkg: ""
    property string actionMode: "install"
    property var selectedPackages: ([])
    property var selectedPackageObjects: ({
    })
    property string accumulatedSearchOutput: ""
    property var currentDetailPkg: null
    property string currentDetailText: ""
    property alias resultsModel: resultsModel
    property string searchFieldText: ""
    property string selectedCategory: "all"

    function showPackageDetails(pkgName, installed) {
        root.currentDetailPkg = {
            "name": pkgName,
            "installed": !!installed
        };
        root.currentDetailText = "Loading details...";
        detailsOverlay.visible = true;
        detailsProc.command = installed ? ["env", "LANG=C", "yay", "-Qi", pkgName] : ["env", "LANG=C", "yay", "-Si", pkgName];
        detailsProc.running = false;
        detailsProc.running = true;
    }

    function restartDebounceTimer() {
        debounceTimer.restart();
    }

    function isDebounceTimerRunning() {
        return debounceTimer.running;
    }

    function startFocusTimer() {
        focusTimer.start();
    }

    function doSearch(query) {
        if (root.actionMode === "install") {
            if (query.length === 0) {
                searchProc.running = false;
                startSearchTimer.nextCommand = ["--featured", root.selectedCategory];
                startSearchTimer.restart();
            } else if (query.length < 2) {
                root.allResults = [];
                root.updateModel();
                root.isSearching = false;
                startSearchTimer.stop();
                return ;
            } else {
                searchProc.running = false;
                startSearchTimer.nextCommand = [query];
                startSearchTimer.restart();
            }
        } else if (root.actionMode === "remove") {
            searchProc.running = false;
            startSearchTimer.nextCommand = ["--list-installed"];
            startSearchTimer.restart();
        } else if (root.actionMode === "update") {
            searchProc.running = false;
            startSearchTimer.nextCommand = ["--list-updates"];
            startSearchTimer.restart();
        }
    }

    function updateModel() {
        let currentPkgName = "";
        let listV = contentComp.getListView();
        if (listV && listV.currentIndex >= 0 && resultsModel.count > listV.currentIndex)
            currentPkgName = resultsModel.get(listV.currentIndex).name;

        resultsModel.clear();
        let data = root.allResults;
        if ((root.actionMode === "remove" || root.actionMode === "update") && root.searchText.length > 0) {
            let q = root.searchText.toLowerCase();
            data = data.filter(function(p) {
                return p.name.toLowerCase().indexOf(q) !== -1 || p.description.toLowerCase().indexOf(q) !== -1;
            });
        }
        let selectedNames = root.selectedPackages;
        let newItems = [];
        for (let i = 0; i < data.length; i++) {
            let pkg = data[i];
            let isSel = selectedNames.indexOf(pkg.name) !== -1;
            newItems.push({
                "name": pkg.name,
                "version": pkg.version,
                "repo": pkg.repo,
                "source": pkg.source,
                "description": pkg.description,
                "installed": pkg.installed,
                "selected": isSel
            });
        }
        if (newItems.length > 0)
            resultsModel.append(newItems);

        if (listV) {
            let found = false;
            if (currentPkgName !== "") {
                for (let i = 0; i < resultsModel.count; i++) {
                    if (resultsModel.get(i).name === currentPkgName) {
                        listV.currentIndex = i;
                        found = true;
                        break;
                    }
                }
            }
            if (!found)
                listV.currentIndex = resultsModel.count > 0 ? 0 : -1;

            if (resultsModel.count > 0 && !root.searchFieldRef.textField.activeFocus)
                listV.forceActiveFocus();

        }
    }

    function toggleSelect(pkgName) {
        let arr = root.selectedPackages.slice();
        let idx = arr.indexOf(pkgName);
        let objs = Object.assign({
        }, root.selectedPackageObjects);
        if (idx !== -1) {
            arr.splice(idx, 1);
            delete objs[pkgName];
        } else {
            arr.push(pkgName);
            let found = false;
            for (let i = 0; i < resultsModel.count; i++) {
                if (resultsModel.get(i).name === pkgName) {
                    objs[pkgName] = {
                        "name": resultsModel.get(i).name,
                        "version": resultsModel.get(i).version,
                        "repo": resultsModel.get(i).repo,
                        "source": resultsModel.get(i).source,
                        "description": resultsModel.get(i).description,
                        "installed": resultsModel.get(i).installed
                    };
                    found = true;
                    break;
                }
            }
            if (!found) {
                for (let i = 0; i < root.allResults.length; i++) {
                    if (root.allResults[i].name === pkgName) {
                        objs[pkgName] = {
                            "name": root.allResults[i].name,
                            "version": root.allResults[i].version,
                            "repo": root.allResults[i].repo,
                            "source": root.allResults[i].source,
                            "description": root.allResults[i].description,
                            "installed": root.allResults[i].installed
                        };
                        found = true;
                        break;
                    }
                }
            }
        }
        root.selectedPackages = arr;
        root.selectedPackageObjects = objs;
        for (let i = 0; i < resultsModel.count; i++) {
            if (resultsModel.get(i).name === pkgName) {
                resultsModel.setProperty(i, "selected", idx === -1);
                break;
            }
        }
    }

    function executeBatch() {
        if (root.selectedPackages.length === 0)
            return ;

        let names = root.selectedPackages.join(" ");
        if (root.actionMode === "remove") {
            removeProc.running = false;
            removeProc.command = ["kitty", "--class", "kitty-floating", "--hold", "-e", "yay", "-Rns"].concat(root.selectedPackages);
            removeProc.startDetached();
        } else if (root.actionMode === "update") {
            installProc.running = false;
            installProc.command = ["kitty", "--class", "kitty-floating", "--hold", "-e", "yay", "-Syu"].concat(root.selectedPackages);
            UpdateService.isSystemUpdating = true;
            installProc.startDetached();
        } else {
            installProc.running = false;
            installProc.command = ["kitty", "--class", "kitty-floating", "--hold", "-e", "yay", "-S"].concat(root.selectedPackages);
            installProc.startDetached();
        }
        root.selectedPackages = [];
        focusKittyTimer.start();
        root.isOpen = false;
    }

    function installPackage(name) {
        root.installingPkg = name;
        installProc.running = false;
        installProc.command = ["kitty", "--class", "kitty-floating", "--hold", "-e", "yay", "-S", name];
        installProc.startDetached();
        focusKittyTimer.start();
        root.isOpen = false;
    }

    function removePackage(name) {
        root.installingPkg = name;
        removeProc.running = false;
        removeProc.command = ["kitty", "--class", "kitty-floating", "--hold", "-e", "yay", "-Rns", name];
        removeProc.startDetached();
        focusKittyTimer.start();
        root.isOpen = false;
    }

    function handleKeyPress(event, fromSearch) {
        let listV = contentComp.getListView();
        let cols = listV.cols || 1;
        if (event.key === Qt.Key_Down) {
            if (fromSearch) {
                if (listV.count > 0) {
                    listV.forceActiveFocus();
                    if (listV.currentIndex === -1)
                        listV.currentIndex = 0;

                    event.accepted = true;
                }
                return ;
            }
            if (listV.count > 0) {
                if (listV.currentIndex === -1)
                    listV.currentIndex = 0;
                else if (listV.currentIndex + cols < listV.count)
                    listV.currentIndex += cols;
                else
                    listV.currentIndex = listV.count - 1;
                event.accepted = true;
            }
        } else if (event.key === Qt.Key_Up) {
            if (fromSearch)
                return ;

            if (listV.currentIndex < cols) {
                root.searchFieldRef.textField.forceActiveFocus();
                event.accepted = true;
            } else if (listV.currentIndex > -1) {
                if (listV.currentIndex >= cols)
                    listV.currentIndex -= cols;

                event.accepted = true;
            }
        } else if (event.key === Qt.Key_Right) {
            if (fromSearch)
                return ;

            // Allow cursor navigation in text field
            if (listV.count > 0 && listV.currentIndex < listV.count - 1) {
                listV.currentIndex++;
                event.accepted = true;
            }
        } else if (event.key === Qt.Key_Left) {
            if (fromSearch)
                return ;

            // Allow cursor navigation in text field
            if (listV.currentIndex > 0) {
                listV.currentIndex--;
                event.accepted = true;
            }
        } else if (event.key === Qt.Key_Slash) {
            if (!fromSearch && !detailsOverlay.visible) {
                root.searchFieldRef.textField.forceActiveFocus();
                root.searchFieldRef.textField.selectAll();
                event.accepted = true;
                return ;
            }
        } else if (event.key === Qt.Key_Escape) {
            if (!fromSearch) {
                root.searchFieldRef.textField.forceActiveFocus();
                event.accepted = true;
                return ;
            }
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            let idx = listV.currentIndex >= 0 ? listV.currentIndex : 0;
            if (root.selectedPackages.length === 0 && resultsModel.count > idx) {
                let pkg = resultsModel.get(idx);
                root.selectedPackages = [pkg.name];
            }
            root.executeBatch();
            event.accepted = true;
        } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
            if (event.modifiers & Qt.ControlModifier) {
                if (event.key === Qt.Key_Backtab || (event.modifiers & Qt.ShiftModifier)) {
                    if (root.actionMode === "install")
                        root.actionMode = "update";
                    else if (root.actionMode === "update")
                        root.actionMode = "remove";
                    else
                        root.actionMode = "install";
                } else {
                    if (root.actionMode === "install")
                        root.actionMode = "remove";
                    else if (root.actionMode === "remove")
                        root.actionMode = "update";
                    else
                        root.actionMode = "install";
                }
                root.selectedPackages = [];
                root.selectedPackageObjects = {
                };
                root.allResults = [];
                resultsModel.clear();
                root.searchFieldRef.textField.text = "";
                root.searchText = "";
                root.doSearch("");
                root.triggerDelayedFocus();
            } else {
                let idx = listV.currentIndex >= 0 ? listV.currentIndex : 0;
                if (resultsModel.count > idx) {
                    let pkg = resultsModel.get(idx);
                    root.toggleSelect(pkg.name);
                }
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_I && (event.modifiers & Qt.ControlModifier)) {
            let idx = listV.currentIndex >= 0 ? listV.currentIndex : 0;
            if (resultsModel.count > idx) {
                let pkg = resultsModel.get(idx);
                root.showPackageDetails(pkg.name, pkg.installed);
            }
            event.accepted = true;
        }
    }

    placeholderText: root.actionMode === "remove" ? "Search installed..." : "Search to install..."
    tabsModel: [{
        "label": "Discover",
        "val": "install"
    }, {
        "label": "Installed",
        "val": "remove"
    }, {
        "label": "Updates",
        "val": "update"
    }]
    activeTabValue: root.actionMode
    hideSearchBar: root.actionMode === "update"
    statusText: {
        if (root.actionMode === "update")
            return root.allResults.length + " updates available";

        if (root.searchText.length > 0)
            return resultsModel.count + " found";

        if (root.actionMode === "remove")
            return resultsModel.count + " installed";

        return "";
    }
    enableTabTransition: true
    onSearchRequested: (text) => {
        root.searchText = text;
        root.restartDebounceTimer();
    }
    onTabClicked: (val, index) => {
        if (root.actionMode === val)
            return ;

        root.actionMode = val;
        root.selectedPackages = [];
        root.selectedPackageObjects = {
        };
        root.allResults = [];
        resultsModel.clear();
        root.searchFieldRef.textField.text = "";
        root.searchText = "";
        root.doSearch("");
        root.triggerDelayedFocus();
    }
    onSearchKeyPress: (event, fromSearch) => {
        root.handleKeyPress(event, fromSearch);
    }
    onEscapePressed: {
        if (contentComp)
            contentComp.focusListView();
        else
            root.searchFieldRef.textField.focus = false;
    }
    popupId: "packagemanager"
    windowTitle: "Minflair Package Manager"
    onIsOpenChanged: {
        if (isOpen) {
            if (root.searchFieldRef)
                root.searchFieldRef.textField.text = "";

            root.allResults = [];
            root.installingPkg = "";
            root.actionMode = SettingsService.packageManagerMode;
            root.selectedPackages = [];
            root.selectedPackageObjects = {
            };
            root.doSearch("");
        } else {
            SettingsService.packageManagerMode = "install";
        }
    }
    onWindowReadyForFocus: {
        contentComp.focusListView();
    }
    overlayData: [
        PackageDetailsOverlay {
            id: detailsOverlay

            anchors.fill: parent
            visible: false
            managerRoot: root
        }
    ]

    Timer {
        id: startSearchTimer

        property var nextCommand: []

        interval: 10
        repeat: false
        onTriggered: {
            root.isSearching = true;
            root.accumulatedSearchOutput = "";
            let baseCmd = ["python3", Quickshell.shellDir + "/Scripts/search_packages.py"];
            searchProc.command = baseCmd.concat(nextCommand);
            searchProc.running = true;
        }
    }

    ListModel {
        id: resultsModel
    }

    Timer {
        id: focusKittyTimer

        interval: 300
        repeat: false
        onTriggered: {
            focusKittyProc.running = false;
            focusKittyProc.command = ["hyprctl", "dispatch", "focuswindow", "class:kitty-floating"];
            focusKittyProc.startDetached();
        }
    }

    Timer {
        id: debounceTimer

        interval: 300
        repeat: false
        onTriggered: {
            if (root.actionMode === "remove" || root.actionMode === "update")
                root.updateModel();
            else
                root.doSearch(root.searchText);
        }
    }

    Process {
        id: searchProc

        command: ["echo", ""]
        onExited: function(exitCode) {
            if (searchProc.running || startSearchTimer.running)
                return ;

            root.isSearching = false;
            if (exitCode === 0) {
                try {
                    root.allResults = JSON.parse(root.accumulatedSearchOutput);
                    if (root.actionMode === "update") {
                        let arr = [];
                        let objs = {
                        };
                        for (let i = 0; i < root.allResults.length; i++) {
                            let pkg = root.allResults[i];
                            arr.push(pkg.name);
                            objs[pkg.name] = {
                                "name": pkg.name,
                                "version": pkg.version,
                                "repo": pkg.repo,
                                "source": pkg.source,
                                "description": pkg.description,
                                "installed": pkg.installed
                            };
                        }
                        root.selectedPackages = arr;
                        root.selectedPackageObjects = objs;
                    }
                    root.updateModel();
                } catch (e) {
                    console.error("PackageManager: Error parsing search results: " + e);
                    root.allResults = [];
                    resultsModel.clear();
                }
            }
            root.accumulatedSearchOutput = "";
            root.triggerDelayedFocus();
        }

        stdout: SplitParser {
            onRead: (data) => {
                root.accumulatedSearchOutput += data;
            }
        }

    }

    Process {
        id: installProc

        onExited: (code) => {
            UpdateService.isSystemUpdating = false;
        }
    }

    Process {
        id: removeProc
    }

    Process {
        id: copyNameProc
    }

    Process {
        id: focusKittyProc
    }

    Process {
        id: detailsProc

        onExited: (code) => {
            if (code !== 0 && root.currentDetailText === "Loading details...")
                root.currentDetailText = "Could not load package details.";

        }

        stdout: SplitParser {
            onRead: (data) => {
                if (root.currentDetailText === "Loading details...")
                    root.currentDetailText = "";

                root.currentDetailText += data + "\n";
            }
        }

    }

    PackageManagerContent {
        id: contentComp

        anchors.fill: parent
        managerRoot: root
    }

}
