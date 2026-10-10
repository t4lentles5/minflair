import QtQuick
import Quickshell
import Quickshell.Io
import qs.Core.Services

Item {
    id: controller

    required property var managerRoot
    property string searchText: ""
    property var allResults: []
    property string installingPkg: ""
    property string actionMode: "install"
    property var selectedPackages: []
    property var selectedPackageObjects: ({
    })
    property string accumulatedSearchOutput: ""
    property var currentDetailPkg: null
    property string currentDetailText: ""
    property string selectedCategory: "featured"
    property string currentSearchQuery: ""
    property bool isSearching: false
    readonly property var categoryList: ["featured", "internet", "development", "multimedia", "gaming", "utilities", "office"]
    readonly property alias resultsModel: resultsModel

    function stopSearchTimers() {
        startSearchTimer.stop();
        if (searchProc.running)
            searchProc.running = false;

        controller.isSearching = false;
    }

    function showPackageDetails(pkgName, installed) {
        controller.currentDetailPkg = {
            "name": pkgName,
            "installed": !!installed
        };
        controller.currentDetailText = "Loading details...";
        if (managerRoot.detailsOverlayRef)
            managerRoot.detailsOverlayRef.visible = true;

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
        if (managerRoot.focusTimerRef)
            managerRoot.focusTimerRef.start();

    }

    function focusSearch() {
        if (managerRoot.searchFieldRef && managerRoot.searchFieldRef.textField) {
            managerRoot.searchFieldRef.textField.forceActiveFocus();
            managerRoot.searchFieldRef.textField.selectAll();
        }
    }

    function getNavIndex(mode, cat) {
        if (mode === "remove")
            return 7;

        if (mode === "update")
            return 8;

        let idx = controller.categoryList.indexOf(cat);
        return idx !== -1 ? idx : 0;
    }

    function switchMode(val) {
        if (controller.actionMode === val)
            return ;

        let prevIdx = controller.getNavIndex(controller.actionMode, controller.selectedCategory);
        let nextIdx = controller.getNavIndex(val, controller.selectedCategory);
        let dir = nextIdx > prevIdx ? 1 : -1;
        startSearchTimer.stop();
        if (searchProc.running)
            searchProc.running = false;

        debounceTimer.stop();
        controller.isSearching = false;
        controller.currentSearchQuery = "";
        let applyChange = function applyChange() {
            controller.actionMode = val;
            controller.selectedPackages = [];
            controller.selectedPackageObjects = ({
            });
            controller.allResults = [];
            resultsModel.clear();
            if (managerRoot.searchFieldRef)
                managerRoot.searchFieldRef.textField.text = "";

            controller.searchText = "";
            controller.doSearch("");
            managerRoot.triggerDelayedFocus();
        };
        if (managerRoot.pageTransitionRef)
            managerRoot.pageTransitionRef.triggerTransition(dir, applyChange);
        else
            applyChange();
    }

    function switchCategory(cat) {
        if (controller.selectedCategory === cat && controller.actionMode === "install")
            return ;

        let prevIdx = controller.getNavIndex(controller.actionMode, controller.selectedCategory);
        let nextIdx = controller.getNavIndex("install", cat);
        let dir = nextIdx > prevIdx ? 1 : -1;
        let applyChange = function applyChange() {
            controller.selectedCategory = cat;
            if (controller.actionMode !== "install")
                controller.actionMode = "install";

            controller.allResults = [];
            resultsModel.clear();
            if (managerRoot.searchFieldRef)
                managerRoot.searchFieldRef.textField.text = "";

            controller.searchText = "";
            controller.doSearch("");
        };
        if (managerRoot.pageTransitionRef)
            managerRoot.pageTransitionRef.triggerTransition(dir, applyChange);
        else
            applyChange();
    }

    function doSearch(query) {
        if (controller.actionMode === "install") {
            if (query.length === 0) {
                searchProc.running = false;
                startSearchTimer.targetQuery = "";
                startSearchTimer.nextCommand = ["--featured", controller.selectedCategory];
                startSearchTimer.restart();
            } else if (query.length < 2) {
                controller.currentSearchQuery = "";
                controller.allResults = [];
                controller.updateModel();
                controller.isSearching = false;
                startSearchTimer.stop();
                return ;
            } else {
                searchProc.running = false;
                startSearchTimer.targetQuery = query;
                startSearchTimer.nextCommand = [query];
                startSearchTimer.restart();
            }
        } else if (controller.actionMode === "remove") {
            searchProc.running = false;
            startSearchTimer.targetQuery = "";
            startSearchTimer.nextCommand = ["--list-installed"];
            startSearchTimer.restart();
        } else if (controller.actionMode === "update") {
            searchProc.running = false;
            startSearchTimer.targetQuery = "";
            startSearchTimer.nextCommand = ["--list-updates"];
            startSearchTimer.restart();
        }
    }

    function updateModel() {
        let currentPkgName = "";
        let listV = managerRoot.contentCompRef ? managerRoot.contentCompRef.getListView() : null;
        if (listV && listV.currentIndex >= 0 && resultsModel.count > listV.currentIndex)
            currentPkgName = resultsModel.get(listV.currentIndex).name;

        resultsModel.clear();
        let data = controller.allResults;
        if ((controller.actionMode === "remove" || controller.actionMode === "update") && controller.searchText.length > 0) {
            let q = controller.searchText.toLowerCase();
            data = data.filter(function(p) {
                return (p.name && p.name.toLowerCase().indexOf(q) !== -1) || (p.description && p.description.toLowerCase().indexOf(q) !== -1);
            });
        }
        for (let i = 0; i < data.length; i++) {
            let p = data[i];
            resultsModel.append({
                "name": p.name,
                "version": p.version || "",
                "repo": p.repo || "",
                "source": p.source || "",
                "description": p.description || "",
                "installed": !!p.installed,
                "selected": controller.selectedPackages.indexOf(p.name) !== -1
            });
        }
        if (listV) {
            let restored = false;
            if (currentPkgName !== "") {
                for (let i = 0; i < resultsModel.count; i++) {
                    if (resultsModel.get(i).name === currentPkgName) {
                        listV.currentIndex = i;
                        restored = true;
                        break;
                    }
                }
            }
            if (!restored)
                listV.currentIndex = resultsModel.count > 0 ? 0 : -1;

        }
    }

    function toggleSelect(pkgName) {
        let arr = controller.selectedPackages.slice();
        let objs = Object.assign({
        }, controller.selectedPackageObjects);
        let idx = arr.indexOf(pkgName);
        if (idx !== -1) {
            arr.splice(idx, 1);
            delete objs[pkgName];
        } else {
            arr.push(pkgName);
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
                    break;
                }
            }
            if (!objs[pkgName]) {
                for (let i = 0; i < controller.allResults.length; i++) {
                    if (controller.allResults[i].name === pkgName) {
                        objs[pkgName] = {
                            "name": controller.allResults[i].name,
                            "version": controller.allResults[i].version,
                            "repo": controller.allResults[i].repo,
                            "source": controller.allResults[i].source,
                            "description": controller.allResults[i].description,
                            "installed": controller.allResults[i].installed
                        };
                        break;
                    }
                }
            }
        }
        controller.selectedPackages = arr;
        controller.selectedPackageObjects = objs;
        for (let i = 0; i < resultsModel.count; i++) {
            if (resultsModel.get(i).name === pkgName) {
                resultsModel.setProperty(i, "selected", idx === -1);
                break;
            }
        }
    }

    function executeBatch() {
        if (controller.selectedPackages.length === 0)
            return ;

        if (controller.actionMode === "remove") {
            removeProc.running = false;
            removeProc.command = ["kitty", "--class", "kitty-floating", "--hold", "-e", "yay", "-Rns"].concat(controller.selectedPackages);
            removeProc.startDetached();
        } else if (controller.actionMode === "update") {
            installProc.running = false;
            installProc.command = ["kitty", "--class", "kitty-floating", "--hold", "-e", "yay", "-Syu"].concat(controller.selectedPackages);
            UpdateService.isSystemUpdating = true;
            installProc.startDetached();
        } else {
            installProc.running = false;
            installProc.command = ["kitty", "--class", "kitty-floating", "--hold", "-e", "yay", "-S"].concat(controller.selectedPackages);
            installProc.startDetached();
        }
        controller.selectedPackages = [];
        focusKittyTimer.start();
        managerRoot.isOpen = false;
    }

    function installPackage(name) {
        controller.installingPkg = name;
        installProc.running = false;
        installProc.command = ["kitty", "--class", "kitty-floating", "--hold", "-e", "yay", "-S", name];
        installProc.startDetached();
        focusKittyTimer.start();
        managerRoot.isOpen = false;
    }

    function removePackage(name) {
        controller.installingPkg = name;
        removeProc.running = false;
        removeProc.command = ["kitty", "--class", "kitty-floating", "--hold", "-e", "yay", "-Rns", name];
        removeProc.startDetached();
        focusKittyTimer.start();
        managerRoot.isOpen = false;
    }

    function handleKeyPress(event, fromSearch) {
        let listV = managerRoot.contentCompRef ? managerRoot.contentCompRef.getListView() : null;
        if (!listV)
            return ;

        let cols = listV.cols || 1;
        if (event.key === Qt.Key_Down) {
            if (fromSearch) {
                if (listV.count > 0) {
                    listV.forceActiveFocus();
                    listV.currentIndex = 0;
                    event.accepted = true;
                }
            } else {
                if (listV.currentIndex + cols < listV.count) {
                    listV.currentIndex += cols;
                    event.accepted = true;
                }
            }
        } else if (event.key === Qt.Key_Up) {
            if (!fromSearch) {
                if (listV.currentIndex - cols >= 0) {
                    listV.currentIndex -= cols;
                    event.accepted = true;
                } else {
                    controller.focusSearch();
                    event.accepted = true;
                }
            }
        } else if (event.key === Qt.Key_Right) {
            if (fromSearch)
                return ;

            if (listV.count > 0 && listV.currentIndex < listV.count - 1) {
                listV.currentIndex++;
                event.accepted = true;
            }
        } else if (event.key === Qt.Key_Left) {
            if (fromSearch)
                return ;

            if (listV.currentIndex > 0) {
                listV.currentIndex--;
                event.accepted = true;
            }
        } else if (event.key === Qt.Key_Slash) {
            if (!fromSearch && (!managerRoot.detailsOverlayRef || !managerRoot.detailsOverlayRef.visible)) {
                controller.focusSearch();
                event.accepted = true;
                return ;
            }
        } else if (event.key === Qt.Key_Escape) {
            if (!fromSearch) {
                controller.focusSearch();
                event.accepted = true;
                return ;
            }
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (fromSearch && (debounceTimer.running || (controller.actionMode === "install" && controller.searchText.length >= 2 && controller.currentSearchQuery !== controller.searchText))) {
                debounceTimer.stop();
                if (controller.actionMode === "remove" || controller.actionMode === "update")
                    controller.updateModel();
                else
                    controller.doSearch(controller.searchText);
                event.accepted = true;
                return ;
            }
            let idx = listV.currentIndex >= 0 ? listV.currentIndex : 0;
            if (controller.selectedPackages.length === 0 && resultsModel.count > idx) {
                let pkg = resultsModel.get(idx);
                controller.selectedPackages = [pkg.name];
            }
            controller.executeBatch();
            event.accepted = true;
        } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
            if (event.modifiers & Qt.ControlModifier) {
                let modes = ["install", "remove", "update"];
                let cIdx = modes.indexOf(controller.actionMode);
                if (cIdx === -1)
                    cIdx = 0;

                let nextMode = (event.key === Qt.Key_Backtab || (event.modifiers & Qt.ShiftModifier)) ? modes[(cIdx - 1 + modes.length) % modes.length] : modes[(cIdx + 1) % modes.length];
                controller.switchMode(nextMode);
            } else {
                let idx = listV.currentIndex >= 0 ? listV.currentIndex : 0;
                if (resultsModel.count > idx) {
                    let pkg = resultsModel.get(idx);
                    controller.toggleSelect(pkg.name);
                }
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_I && (event.modifiers & Qt.ControlModifier)) {
            let idx = listV.currentIndex >= 0 ? listV.currentIndex : 0;
            if (resultsModel.count > idx) {
                let pkg = resultsModel.get(idx);
                controller.showPackageDetails(pkg.name, pkg.installed);
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_R && (event.modifiers & Qt.ControlModifier)) {
            controller.switchMode("remove");
            event.accepted = true;
        } else if (event.key === Qt.Key_U && (event.modifiers & Qt.ControlModifier)) {
            controller.switchMode("update");
            event.accepted = true;
        } else if (event.key === Qt.Key_Space) {
            if (!fromSearch) {
                let idx = listV.currentIndex >= 0 ? listV.currentIndex : 0;
                if (resultsModel.count > idx) {
                    let pkg = resultsModel.get(idx);
                    controller.toggleSelect(pkg.name);
                }
                event.accepted = true;
            }
        }
    }

    ListModel {
        id: resultsModel
    }

    Timer {
        id: startSearchTimer

        property var nextCommand: []
        property string targetQuery: ""

        interval: 10
        repeat: false
        onTriggered: {
            controller.isSearching = true;
            controller.accumulatedSearchOutput = "";
            controller.currentSearchQuery = targetQuery;
            let baseCmd = ["python3", Quickshell.shellDir + "/Modules/PackageManager/scripts/search_packages.py"];
            searchProc.command = baseCmd.concat(nextCommand);
            searchProc.running = true;
        }
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

        interval: 700
        repeat: false
        onTriggered: {
            if (controller.actionMode === "remove" || controller.actionMode === "update")
                controller.updateModel();
            else
                controller.doSearch(controller.searchText);
        }
    }

    Process {
        id: searchProc

        command: ["echo", ""]
        onExited: function(exitCode) {
            if (searchProc.running || startSearchTimer.running)
                return ;

            controller.isSearching = false;
            if (controller.actionMode === "install" && controller.searchText !== "" && controller.currentSearchQuery !== controller.searchText) {
                controller.accumulatedSearchOutput = "";
                return ;
            }
            if (exitCode === 0) {
                try {
                    controller.allResults = JSON.parse(controller.accumulatedSearchOutput);
                    if (controller.actionMode === "update") {
                        let arr = [];
                        let objs = ({
                        });
                        for (let i = 0; i < controller.allResults.length; i++) {
                            let pkg = controller.allResults[i];
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
                        controller.selectedPackages = arr;
                        controller.selectedPackageObjects = objs;
                    }
                    controller.updateModel();
                } catch (e) {
                    console.error("PackageManager: Error parsing search results: " + e);
                    controller.allResults = [];
                    resultsModel.clear();
                }
            }
            controller.accumulatedSearchOutput = "";
            managerRoot.triggerDelayedFocus();
        }

        stdout: SplitParser {
            onRead: (data) => {
                controller.accumulatedSearchOutput += data;
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
        id: focusKittyProc
    }

    Process {
        id: detailsProc

        onExited: (code) => {
            if (code !== 0 && controller.currentDetailText === "Loading details...")
                controller.currentDetailText = "Could not load package details.";

        }

        stdout: SplitParser {
            onRead: (data) => {
                if (controller.currentDetailText === "Loading details...")
                    controller.currentDetailText = "";

                controller.currentDetailText += data + "\n";
            }
        }

    }

}
