import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Core
import qs.Core.Components
import qs.Core.Services

Item {
    id: root

    property var widget: null
    property var shotModel: {
        let items = [{
            "label": "Full Screen",
            "icon": "monitor",
            "shotMode": "full",
            "actionType": "shot"
        }, {
            "label": "Select Area",
            "icon": "screenshot-area",
            "shotMode": "area",
            "actionType": "shot"
        }, {
            "label": "Area (3s)",
            "icon": "3s",
            "shotMode": "area_3s",
            "actionType": "shot"
        }, {
            "label": "Current Window",
            "icon": "window",
            "shotMode": "window",
            "actionType": "shot"
        }, {
            "label": "Extract Text",
            "icon": "ocr",
            "shotMode": "ocr",
            "actionType": "shot"
        }];
        if (RecorderService.running) {
            items.push({
                "label": "Stop Record",
                "icon": "player-stop",
                "shotMode": "stop_record",
                "actionType": "record"
            });
        } else {
            items.push({
                "label": "Record Area",
                "icon": "record-area",
                "shotMode": "record_area",
                "actionType": "record"
            });
            items.push({
                "label": "Record Full",
                "icon": "record-icon",
                "shotMode": "record_full",
                "actionType": "record"
            });
        }
        return items;
    }
    property alias initialFocusItem: shotView

    function hideWidget() {
        if (root.widget && typeof root.widget.close === "function")
            root.widget.close();
        else if (root.widget && root.widget.close !== undefined)
            root.widget.close();
        else if (root.widget && root.widget.isOpen !== undefined)
            root.widget.isOpen = false;
        AppState.activePopup = "";
    }

    function runShot(mode) {
        let scriptPath = Quickshell.shellDir + "/Scripts/screenshot.sh";
        Quickshell.execDetached(["bash", scriptPath, mode]);
        root.hideWidget();
    }

    function resetScreenCapture() {
        shotView.currentIndex = 0;
        shotView.forceActiveFocus();
    }

    implicitWidth: 64 * root.shotModel.length
    implicitHeight: 48
    anchors.fill: parent
    Component.onCompleted: {
        resetScreenCapture();
    }

    Connections {
        function onRunningChanged() {
            if (RecorderService.running)
                root.hideWidget();

        }

        target: RecorderService
    }

    ActionMenu {
        id: shotView

        anchors.fill: parent
        actionModel: root.shotModel
        onActionTriggered: (index) => {
            let item = root.shotModel[index];
            if (item.actionType === "shot") {
                root.runShot(item.shotMode);
            } else if (item.actionType === "record") {
                if (item.shotMode === "record_area")
                    RecorderService.toggle(["-s", "-r"]);
                else if (item.shotMode === "record_full")
                    RecorderService.toggle(["-s"]);
                else
                    RecorderService.toggle();
                root.hideWidget();
            }
        }
    }

}
