import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Core
import qs.Core.Components
import qs.Core.Services

Item {
    id: root

    property var widget: null
    property var menuModel: [{
        "id": "lock",
        "label": "Lock",
        "icon": "lock",
        "command": ["sh", "-c", "sleep 0.3; socat - UNIX-CONNECT:/tmp/quickshell_lockScreen"],
        "confirm": false
    }, {
        "id": "suspend",
        "label": "Suspend",
        "icon": "moon",
        "command": ["sh", "-c", "mpc -q pause; amixer set Master mute; systemctl suspend"],
        "confirm": true
    }, {
        "id": "logout",
        "label": "Logout",
        "icon": "logout",
        "command": ["hyprctl", "dispatch", "exit"],
        "confirm": true
    }, {
        "id": "reboot",
        "label": "Reboot",
        "icon": "reload",
        "command": ["systemctl", "reboot"],
        "confirm": true
    }, {
        "id": "shutdown",
        "label": "Shutdown",
        "icon": "power",
        "command": ["systemctl", "poweroff"],
        "confirm": true
    }]
    property int pendingActionIndex: -1
    property alias initialFocusItem: menuView

    function closeWidget() {
        if (root.widget && typeof root.widget.close === "function")
            root.widget.close();
        else if (root.widget && root.widget.close !== undefined)
            root.widget.close();
        else if (root.widget && root.widget.isOpen !== undefined)
            root.widget.isOpen = false;
        AppState.activePopup = "";
    }

    function runAction(index) {
        if (index >= 0 && index < root.menuModel.length) {
            let modelData = root.menuModel[index];
            if (modelData.confirm) {
                root.pendingActionIndex = index;
            } else {
                actionProc.command = modelData.command;
                actionProc.startDetached();
                root.closeWidget();
            }
        }
    }

    function resetPowerMenu() {
        root.pendingActionIndex = -1;
        menuView.currentIndex = 0;
        menuView.forceActiveFocus();
    }

    implicitWidth: 64 * root.menuModel.length
    implicitHeight: 48
    anchors.fill: parent
    Component.onCompleted: {
        resetPowerMenu();
    }
    onPendingActionIndexChanged: {
        if (pendingActionIndex === -1) {
            menuView.forceActiveFocus();
        } else {
            confirmMenu.currentIndex = 0;
            confirmMenu.forceActiveFocus();
        }
    }

    Process {
        id: actionProc
    }

    ActionMenu {
        id: menuView

        anchors.fill: parent
        visible: opacity > 0
        opacity: root.pendingActionIndex === -1 ? 1 : 0
        scale: root.pendingActionIndex === -1 ? 1 : 0.95
        enabled: root.pendingActionIndex === -1
        actionModel: root.menuModel
        onActionTriggered: (index) => {
            root.runAction(index);
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Constants.animNormal
                easing.type: Easing.OutCubic
            }

        }

        Behavior on scale {
            NumberAnimation {
                duration: Constants.animNormal
                easing.type: Easing.OutBack
            }

        }

    }

    RowLayout {
        id: confirmView

        anchors.fill: parent
        visible: opacity > 0
        opacity: root.pendingActionIndex !== -1 ? 1 : 0
        scale: root.pendingActionIndex !== -1 ? 1 : 0.95
        enabled: root.pendingActionIndex !== -1
        spacing: 0

        Item {
            Layout.preferredWidth: Constants.sizeLg
        }

        ThemedText {
            text: "Confirm " + (root.pendingActionIndex !== -1 ? root.menuModel[root.pendingActionIndex].label : "") + "?"
            font.bold: true
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignLeft
        }

        ActionMenu {
            id: confirmMenu

            actionModel: [{
                "label": "Cancel",
                "icon": "x"
            }, {
                "label": "Confirm",
                "icon": "check"
            }]
            onActionTriggered: (index) => {
                if (index === 1) {
                    let modelData = root.menuModel[root.pendingActionIndex];
                    actionProc.command = modelData.command;
                    actionProc.startDetached();
                    root.closeWidget();
                } else {
                    root.pendingActionIndex = -1;
                }
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Constants.animNormal
                easing.type: Easing.OutCubic
            }

        }

        Behavior on scale {
            NumberAnimation {
                duration: Constants.animNormal
                easing.type: Easing.OutBack
            }

        }

    }

}
