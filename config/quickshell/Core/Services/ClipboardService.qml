import QtQuick
import Quickshell
import Quickshell.Io
import qs.Core
import qs.Core.Services
pragma Singleton

Item {
    id: root

    property alias model: clipboardModel
    property alias filteredModel: filteredModel
    property bool isDeleting: false
    property string currentSearchQuery: ""

    function refresh() {
        loadClipboardProc.running = true;
    }

    function syncModel(listModel, sourceArray) {
        let sourceIds = {
        };
        for (let i = 0; i < sourceArray.length; i++) {
            sourceIds[sourceArray[i].itemId] = true;
        }
        for (let i = listModel.count - 1; i >= 0; i--) {
            if (!sourceIds[listModel.get(i).itemId])
                listModel.remove(i);

        }
        for (let i = 0; i < sourceArray.length; i++) {
            let src = sourceArray[i];
            if (i >= listModel.count) {
                listModel.append(src);
                continue;
            }
            let dest = listModel.get(i);
            if (dest.itemId === src.itemId)
                continue;

            let foundIdx = -1;
            for (let j = i + 1; j < listModel.count; j++) {
                if (listModel.get(j).itemId === src.itemId) {
                    foundIdx = j;
                    break;
                }
            }
            if (foundIdx !== -1)
                listModel.move(foundIdx, i, 1);
            else
                listModel.insert(i, src);
        }
    }

    function filterClipboard(query) {
        currentSearchQuery = query;
        let matchedItems = [];
        let queryLower = query.toLowerCase();
        for (let i = 0; i < clipboardModel.count; i++) {
            let item = clipboardModel.get(i);
            let isImage = item.isImage !== undefined ? item.isImage : false;
            if (item.text.toLowerCase().includes(queryLower) || (isImage && queryLower === ""))
                matchedItems.push({
                    "itemId": item.itemId,
                    "text": item.text,
                    "fullLine": item.fullLine,
                    "isImage": isImage
                });

        }
        syncModel(filteredModel, matchedItems);
    }

    function copyItem(itemId, closeWidgetCallback) {
        if (!itemId)
            return ;

        copyProc.command = ["bash", "-c", "cliphist decode " + itemId + " | wl-copy"];
        copyProc.startDetached();
        if (closeWidgetCallback)
            closeWidgetCallback();

    }

    function deleteItem(index, fullLine) {
        if (index < 0 || index >= filteredModel.count)
            return ;

        isDeleting = true;
        deletingResetTimer.restart();
        filteredModel.remove(index);
        for (let i = 0; i < clipboardModel.count; i++) {
            if (clipboardModel.get(i).fullLine === fullLine) {
                clipboardModel.remove(i);
                break;
            }
        }
        let safeLine = fullLine.replace(/'/g, "'\\''");
        deleteProc.command = ["bash", "-c", "echo '" + safeLine + "' | cliphist delete"];
        deleteProc.startDetached();
    }

    function clearHistory() {
        if (filteredModel.count === 0)
            return ;

        isDeleting = true;
        deletingResetTimer.restart();
        clipboardModel.clear();
        filteredModel.remove(0, filteredModel.count);
        clearProc.running = false;
        clearProc.running = true;
    }

    ListModel {
        id: clipboardModel
    }

    ListModel {
        id: filteredModel
    }

    Process {
        id: loadClipboardProc

        command: ["cliphist", "list"]
        onExited: function(exitCode) {
            if (exitCode === 0) {
                clipboardModel.clear();
                let output = clipboardOutput.text.trim();
                if (output === "") {
                    root.filterClipboard("");
                    return ;
                }
                let lines = output.split('\n');
                if (SettingsService.clipboardMaxItems > 0)
                    lines = lines.slice(0, SettingsService.clipboardMaxItems);

                let imageIds = [];
                lines.forEach(function(line) {
                    if (line.trim() === "")
                        return ;

                    let parts = line.split('\t');
                    if (parts.length >= 2) {
                        let text = parts.slice(1).join('\t');
                        let isImage = text.startsWith("[[ binary data") && text.includes("]]");
                        if (isImage)
                            imageIds.push(parts[0]);

                        clipboardModel.append({
                            "itemId": parts[0],
                            "text": text,
                            "fullLine": line,
                            "isImage": isImage
                        });
                    }
                });
                if (imageIds.length > 0) {
                    let cmd = "mkdir -p /tmp/quickshell-clipboard && for id in " + imageIds.join(" ") + "; do if [ ! -f /tmp/quickshell-clipboard/$id.png ]; then cliphist decode $id > /tmp/quickshell-clipboard/$id.png; fi; done";
                    decodeImagesProc.command = ["bash", "-c", cmd];
                    decodeImagesProc.running = true;
                } else {
                    root.filterClipboard("");
                }
            }
        }

        stdout: StdioCollector {
            id: clipboardOutput
        }

    }

    Process {
        id: decodeImagesProc

        onExited: function(exitCode) {
            root.filterClipboard("");
        }
    }

    Process {
        id: copyProc
    }

    Process {
        id: deleteProc
    }

    Process {
        id: clearProc

        command: ["cliphist", "wipe"]
        onExited: function(exitCode) {
            if (exitCode === 0)
                loadClipboardProc.running = true;

        }
    }

    Timer {
        id: deletingResetTimer

        interval: Constants.animNormal * 2 + 50
        repeat: false
        onTriggered: root.isDeleting = false
    }

}
