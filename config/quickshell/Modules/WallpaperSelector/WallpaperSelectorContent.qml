import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.Core
import qs.Core.Components
import qs.Core.Services

Item {
    id: root

    property var widget: null
    property string searchText: ""
    property alias initialFocusItem: searchField
    property int visibleCards: 4
    readonly property int cardItemWidth: 240
    readonly property int cardItemHeight: 162
    readonly property int searchBarHeight: 38
    readonly property int cardSpacing: Constants.sizeLg
    readonly property int layoutSpacing: Constants.sizeLg

    function ensureVisible(index) {
        if (index < 0 || index >= filteredModel.count)
            return ;

        let spacing = root.cardSpacing;
        let step = root.cardItemWidth + spacing;
        let cardsPerView = root.visibleCards;
        let maxScroll = Math.max(0, (filteredModel.count - cardsPerView) * step);
        let currentX = wallView.contentX;
        let firstVisibleIndex = Math.floor((currentX + 5) / step);
        let lastVisibleIndex = firstVisibleIndex + cardsPerView - 1;
        let targetX = currentX;
        if (index < firstVisibleIndex)
            targetX = index * step;
        else if (index > lastVisibleIndex)
            targetX = (index - cardsPerView + 1) * step;
        targetX = Math.max(0, Math.min(targetX, maxScroll));
        if (Math.abs(targetX - currentX) > 1) {
            scrollAnim.stop();
            scrollAnim.from = currentX;
            scrollAnim.to = targetX;
            scrollAnim.start();
        }
    }

    function selectIndex(idx) {
        if (filteredModel.count === 0)
            return ;

        let newIdx = Math.max(0, Math.min(idx, filteredModel.count - 1));
        wallView.currentIndex = newIdx;
        root.ensureVisible(newIdx);
    }

    function handleKey(event) {
        if (event.key === Qt.Key_Right) {
            root.selectIndex(wallView.currentIndex + 1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Left) {
            root.selectIndex(wallView.currentIndex - 1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Down || event.key === Qt.Key_PageDown) {
            root.selectIndex(wallView.currentIndex + 4);
            event.accepted = true;
        } else if (event.key === Qt.Key_Up || event.key === Qt.Key_PageUp) {
            root.selectIndex(wallView.currentIndex - 4);
            event.accepted = true;
        } else if (event.key === Qt.Key_Home) {
            root.selectIndex(0);
            event.accepted = true;
        } else if (event.key === Qt.Key_End) {
            root.selectIndex(filteredModel.count - 1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            let idx = wallView.currentIndex >= 0 ? wallView.currentIndex : 0;
            if (filteredModel.count > idx) {
                let wall = filteredModel.get(idx);
                setWallpaper(wall.rawPath);
                event.accepted = true;
            }
        } else if (event.key === Qt.Key_Escape) {
            if (root.widget && root.widget.close !== undefined)
                root.widget.close();
            else if (root.widget && root.widget.isOpen !== undefined)
                root.widget.isOpen = false;
            else
                AppState.activePopup = "";
            event.accepted = true;
        }
    }

    function filterWallpapers(query) {
        scrollAnim.stop();
        wallView.contentX = 0;
        filteredModel.clear();
        query = query.toLowerCase();
        for (let i = 0; i < wallModel.count; i++) {
            let wall = wallModel.get(i);
            if (wall.name.toLowerCase().includes(query))
                filteredModel.append(wall);

        }
        if (WallpaperManager.currentWallpaper) {
            for (let j = 0; j < filteredModel.count; j++) {
                if (filteredModel.get(j).name === WallpaperManager.currentWallpaper) {
                    wallView.currentIndex = j;
                    let spacing = Constants.sizeLg;
                    let step = root.cardItemWidth + spacing;
                    let cardsPerView = 4;
                    let maxScroll = Math.max(0, (filteredModel.count - cardsPerView) * step);
                    let initialX = (j >= cardsPerView) ? ((j - cardsPerView + 1) * step) : 0;
                    wallView.contentX = Math.max(0, Math.min(initialX, maxScroll));
                    return ;
                }
            }
        }
        if (filteredModel.count > 0)
            wallView.currentIndex = 0;
        else
            wallView.currentIndex = -1;
    }

    function setWallpaper(targetPath) {
        if (!targetPath)
            return ;

        let parts = targetPath.split('/');
        let wallName = parts[parts.length - 1];
        WallpaperManager.applyWallpaperWithSync(wallName, targetPath);
        if (root.widget && root.widget.close !== undefined)
            root.widget.close();
        else if (root.widget && root.widget.isOpen !== undefined)
            root.widget.isOpen = false;
        else
            AppState.activePopup = "";
    }

    function resetWallpaperSelector() {
        scrollAnim.stop();
        wallView.contentX = 0;
        searchField.text = "";
        loadWallpapersProc.lines = [];
        loadWallpapersProc.running = true;
        searchField.forceActiveFocus();
    }

    implicitWidth: (visibleCards * cardItemWidth) + Math.max(0, (visibleCards - 1) * cardSpacing)
    implicitHeight: searchBarHeight + layoutSpacing + cardItemHeight
    width: implicitWidth
    height: implicitHeight
    focus: true
    Keys.priority: Keys.BeforeItem
    Keys.onPressed: (event) => {
        return root.handleKey(event);
    }
    Component.onCompleted: {
        resetWallpaperSelector();
    }

    NumberAnimation {
        id: scrollAnim

        target: wallView
        property: "contentX"
        duration: Constants.animSlow
        easing.type: Easing.OutQuint
    }

    ListModel {
        id: wallModel
    }

    ListModel {
        id: filteredModel
    }

    Process {
        id: loadWallpapersProc

        property var lines: []

        command: ["bash", "-c", "find ~/Pictures/Wallpapers -maxdepth 2 -type f 2>/dev/null | grep -iE '\\.(jpg|jpeg|png|webp|gif)$'"]
        onExited: function(exitCode) {
            wallModel.clear();
            let sortedLines = lines.sort(function(a, b) {
                return a.name.localeCompare(b.name);
            });
            for (let i = 0; i < sortedLines.length; i++) {
                wallModel.append(sortedLines[i]);
            }
            lines = [];
            filterWallpapers(searchField.text);
        }

        stdout: SplitParser {
            onRead: function(data) {
                let linesArr = data.split('\n');
                for (let i = 0; i < linesArr.length; i++) {
                    let rawPath = linesArr[i].trim();
                    if (rawPath !== "") {
                        let parts = rawPath.split('/');
                        let fileName = parts[parts.length - 1];
                        loadWallpapersProc.lines.push({
                            "filePath": "file://" + rawPath,
                            "rawPath": rawPath,
                            "name": fileName
                        });
                    }
                }
            }
        }

    }

    ColumnLayout {
        anchors.fill: parent
        spacing: root.layoutSpacing

        Item {
            id: topSearchContainer

            Layout.fillWidth: true
            Layout.preferredHeight: 38
            visible: !SettingsService.barConvexMode
        }

        Item {
            id: wallContainer

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: root.cardItemHeight

            GhostEmptyState {
                anchors.centerIn: parent
                visible: filteredModel.count === 0
                text: searchField.text === "" ? "No wallpapers in ~/Pictures/Wallpapers" : "No wallpapers found"
                isAnimating: visible
            }

            ListView {
                id: wallView

                anchors.fill: parent
                orientation: ListView.Horizontal
                spacing: Constants.sizeLg
                clip: true
                model: filteredModel
                currentIndex: -1
                highlightFollowsCurrentItem: false
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.HorizontalFlick
                visible: filteredModel.count > 0

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

                delegate: Item {
                    id: delegateRoot

                    readonly property bool isCurrent: wallView.currentIndex === index
                    readonly property bool isApplied: model.name === WallpaperManager.currentWallpaper

                    width: root.cardItemWidth
                    height: root.cardItemHeight
                    z: isCurrent ? 5 : (hoverHandler.hovered ? 3 : 1)

                    Rectangle {
                        id: cardBg

                        anchors.fill: parent
                        radius: Constants.sizeLg
                        color: Theme.bgSecondary
                        border.color: isCurrent ? Theme.accent : (hoverHandler.hovered ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.35) : Theme.border)
                        border.width: isCurrent ? 2 : 1

                        Item {
                            id: imageMaskContainer

                            anchors.fill: parent
                            anchors.margins: cardBg.border.width
                            layer.enabled: true

                            Image {
                                id: thumbImg

                                anchors.fill: parent
                                source: model.filePath
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                                sourceSize: Qt.size(450, 270)
                                mipmap: true
                                opacity: status === Image.Ready ? 1 : 0

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: Constants.animFast
                                        easing.type: Easing.OutQuint
                                    }

                                }

                            }

                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: parent.height * 0.55

                                gradient: Gradient {
                                    GradientStop {
                                        position: 0
                                        color: "transparent"
                                    }

                                    GradientStop {
                                        position: 0.35
                                        color: Qt.rgba(0, 0, 0, 0.35)
                                    }

                                    GradientStop {
                                        position: 1
                                        color: Qt.rgba(0, 0, 0, 0.85)
                                    }

                                }

                            }

                            layer.effect: OpacityMask {

                                maskSource: Rectangle {
                                    width: imageMaskContainer.width
                                    height: imageMaskContainer.height
                                    radius: Math.max(0, Constants.sizeLg - cardBg.border.width)
                                }

                            }

                        }

                        ThemedText {
                            id: nameText

                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: Constants.sizeSm
                            text: model.name
                            customSize: Constants.sizeSm
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            color: isCurrent ? Theme.accent : "#ffffff"
                            font.bold: isCurrent

                            Behavior on color {
                                ColorAnimation {
                                    duration: Constants.animFast
                                }

                            }

                        }

                        Behavior on border.color {
                            ColorAnimation {
                                duration: Constants.animFast
                            }

                        }

                        Behavior on border.width {
                            NumberAnimation {
                                duration: Constants.animFast
                            }

                        }

                    }

                    HoverHandler {
                        id: hoverHandler

                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        onTapped: {
                            wallView.currentIndex = index;
                            root.ensureVisible(index);
                            setWallpaper(model.rawPath);
                        }
                    }

                }

                ScrollBar.horizontal: ScrollBar {
                    policy: ScrollBar.AlwaysOff
                }

            }

        }

        Item {
            id: bottomSearchContainer

            Layout.fillWidth: true
            Layout.preferredHeight: 38
            visible: SettingsService.barConvexMode
        }

    }

    ThemedSearchBar {
        id: searchField

        parent: SettingsService.barConvexMode ? bottomSearchContainer : topSearchContainer
        anchors.fill: parent
        preferredHeight: 38
        placeholderText: "Search wallpapers..."
        customSize: Constants.sizeMd
        onSearchRequested: (text) => {
            return root.filterWallpapers(text);
        }
        textField.Keys.onPressed: (event) => {
            return root.handleKey(event);
        }
    }

}
