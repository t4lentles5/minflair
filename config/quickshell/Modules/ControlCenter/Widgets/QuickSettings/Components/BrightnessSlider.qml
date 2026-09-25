import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import qs.Core
import qs.Core.Components

ThemedSlider {
    id: root

    property int brightness: 0
    property bool isVisible: true

    function setBrightness(val) {
        let finalVal = Math.max(5, val);
        brightSetProc.command = ["brightnessctl", "s", finalVal + "%"];
        brightSetProc.running = true;
        root.brightness = finalVal;
    }

    value: root.brightness
    icon: "sun"
    onMoved: (val) => {
        return root.setBrightness(val);
    }

    Timer {
        interval: 250
        running: root.isVisible
        repeat: true
        triggeredOnStart: true
        onTriggered: brightGetProc.running = true
    }

    Process {
        id: brightGetProc

        command: ["brightnessctl", "-m"]

        stdout: SplitParser {
            onRead: (data) => {
                if (!data)
                    return ;

                var parts = data.split(",");
                if (parts.length >= 4) {
                    var pct = parts[3];
                    if (pct.endsWith("%"))
                        pct = pct.substring(0, pct.length - 1);

                    if (!root.pressed)
                        root.brightness = parseInt(pct);

                }
            }
        }

    }

    Process {
        id: brightSetProc
    }

}
