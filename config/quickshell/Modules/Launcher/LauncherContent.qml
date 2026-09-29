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
import qs.Modules.Launcher.Components

Item {
    id: root

    property var widget: null
    property string searchText: ""
    property var allApps: []
    property var filteredApps: []
    property alias initialFocusItem: searchField
    property int visibleItems: 8
    property int preferredContentWidth: 700
    readonly property int searchBarHeight: 40
    readonly property int itemHeight: 44
    readonly property int listSpacing: Constants.sizeXs
    readonly property int layoutSpacing: Constants.sizeSm
    readonly property int visibleListHeight: (visibleItems * itemHeight) + Math.max(0, (visibleItems - 1) * listSpacing)

    function filterApps(query) {
        query = query.toLowerCase();
        let newFiltered = [];
        for (let i = 0; i < root.allApps.length; i++) {
            let app = root.allApps[i];
            if (app.name.toLowerCase().includes(query))
                newFiltered.push(app);

        }
        root.filteredApps = newFiltered;
        if (appsView) {
            appsView.expandedIndex = -1;
            if (root.filteredApps.length > 0)
                appsView.currentIndex = 0;
            else
                appsView.currentIndex = -1;
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
            if (root.filteredApps.length > idx) {
                if (currentDelegate && currentDelegate.isExpanded && currentDelegate.currentActionIndex >= 0) {
                    let action = root.filteredApps[idx].actions[currentDelegate.currentActionIndex];
                    launchApp(action.exec, false);
                } else {
                    let app = root.filteredApps[idx];
                    launchApp(app.exec, app.terminal);
                }
                event.accepted = true;
            }
        } else if (event.key === Qt.Key_Escape) {
            if (root.widget && typeof root.widget.close === "function")
                root.widget.close();
            else if (root.widget && root.widget.isOpen !== undefined)
                root.widget.isOpen = false;
            else
                AppState.activePopup = "";
            event.accepted = true;
        }
    }

    function launchApp(exec, terminal) {
        if (!exec)
            return ;

        let command = exec.split(' ').filter(function(arg) {
            return !arg.startsWith('%');
        });
        command = command.map(function(arg) {
            return arg.replace(/^"|"$/g, '');
        });
        if (terminal)
            command = ["kitty", "-e"].concat(command);

        appLauncher.running = false;
        appLauncher.command = command;
        appLauncher.startDetached();
        AppState.closeAllPopups();
        if (root.widget && root.widget.close !== undefined)
            root.widget.close();
        else if (root.widget && root.widget.isOpen !== undefined)
            root.widget.isOpen = false;
    }

    function resetLauncher() {
        if (appsView)
            appsView.expandedIndex = -1;

        searchField.text = "";
        if (AppState.launcherApps && AppState.launcherApps.length > 0) {
            root.allApps = AppState.launcherApps;
            filterApps("");
        } else {
            loadAppsProc.running = true;
        }
        searchField.forceActiveFocus();
    }

    implicitWidth: preferredContentWidth
    implicitHeight: searchBarHeight + layoutSpacing + visibleListHeight
    width: implicitWidth
    height: implicitHeight
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
                    filterApps("");
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
            Layout.preferredHeight: SettingsService.barConvexMode ? 0 : 40
            visible: !SettingsService.barConvexMode
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: root.visibleListHeight
            Layout.fillHeight: false

            GhostEmptyState {
                anchors.centerIn: parent
                visible: root.filteredApps.length === 0 && searchField.text !== ""
                text: "No applications found"
                isAnimating: visible
            }

            ListView {
                id: appsView

                property int expandedIndex: -1

                anchors.fill: parent
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: root.filteredApps
                spacing: root.listSpacing
                currentIndex: -1
                highlightResizeDuration: 0
                highlightMoveDuration: Constants.animNormal
                highlightFollowsCurrentItem: true
                visible: root.filteredApps.length > 0
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
                        duration: Constants.animNormal
                        easing.type: Easing.OutQuint
                    }

                }

                populate: Transition {
                    NumberAnimation {
                        properties: "opacity"
                        from: 0
                        to: 1
                        duration: Constants.animNormal
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
        preferredHeight: 40
        placeholderText: "Search applications..."
        onSearchRequested: (text) => {
            return root.filterApps(text);
        }
        customSize: Constants.sizeMd
        textField.Keys.onPressed: function(event) {
            root.handleKeyPress(event, true);
        }
    }

    Process {
        id: appLauncher
    }

}
