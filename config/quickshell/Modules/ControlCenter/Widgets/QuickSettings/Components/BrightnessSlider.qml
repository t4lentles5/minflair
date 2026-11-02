import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Core
import qs.Core.Components

ThemedSlider {
    id: root

    readonly property string helper: Quickshell.shellDir + "/Scripts/system/brightness.sh"
    property int brightness: 0
    property bool isVisible: true
    property int _pendingBrightness: 0

    function setBrightness(val) {
        let finalVal = Math.max(5, val);
        root.brightness = finalVal;
        root._pendingBrightness = finalVal;
        if (!brightnessThrottleTimer.running)
            brightnessThrottleTimer.start();

    }

    value: root.brightness
    icon: "sun"
    onMoved: (val) => {
        return root.setBrightness(val);
    }
    onIconClicked: root.setBrightness(root.brightness <= 5 ? 100 : 5)

    Timer {
        id: brightnessThrottleTimer

        interval: 35
        repeat: false
        onTriggered: {
            if (!brightSetProc.running) {
                brightSetProc.command = [root.helper, "set", String(root._pendingBrightness)];
                brightSetProc.running = true;
            } else {
                brightnessThrottleTimer.restart();
            }
        }
    }

    Timer {
        interval: 250
        running: root.isVisible && !root.pressed && !brightSetProc.running
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!brightGetProc.running)
                brightGetProc.running = true;

        }
    }

    Process {
        id: brightGetProc

        command: [root.helper, "get"]

        stdout: SplitParser {
            onRead: (data) => {
                var pct = parseInt(data.trim());
                if (!isNaN(pct) && !root.pressed && !brightSetProc.running)
                    root.brightness = Math.max(0, Math.min(100, pct));

            }
        }

    }

    Process {
        id: brightSetProc
    }

}
