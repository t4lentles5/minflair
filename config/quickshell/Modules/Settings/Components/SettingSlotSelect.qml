import QtQuick
import Quickshell
import qs.Core.Components
import qs.Core.Services

ThemedSelect {
    id: root

    property string slotId: ""
    property var updateFn: null
    readonly property var slotOptions: ["none", "workspaces", "media", "clock", "tray", "control_center", "recording"]

    function syncIndex() {
        let idx = slotOptions.indexOf(SettingsService[slotId]);
        currentIndex = idx >= 0 ? idx : 0;
    }

    model: ["None", "Workspaces", "Media Player", "Clock", "System Tray", "Control Center", "Recording Indicator"]
    Component.onCompleted: syncIndex()
    onActivated: (index) => {
        if (updateFn)
            updateFn(slotOptions[index]);

    }

    Connections {
        function onBarSlotL1Changed() {
            if (root.slotId === "barSlotL1")
                root.syncIndex();

        }

        function onBarSlotL2Changed() {
            if (root.slotId === "barSlotL2")
                root.syncIndex();

        }

        function onBarSlotL3Changed() {
            if (root.slotId === "barSlotL3")
                root.syncIndex();

        }

        function onBarSlotC1Changed() {
            if (root.slotId === "barSlotC1")
                root.syncIndex();

        }

        function onBarSlotC2Changed() {
            if (root.slotId === "barSlotC2")
                root.syncIndex();

        }

        function onBarSlotR1Changed() {
            if (root.slotId === "barSlotR1")
                root.syncIndex();

        }

        function onBarSlotR2Changed() {
            if (root.slotId === "barSlotR2")
                root.syncIndex();

        }

        function onBarSlotR3Changed() {
            if (root.slotId === "barSlotR3")
                root.syncIndex();

        }

        target: SettingsService
    }

}
