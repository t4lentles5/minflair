import QtQuick
import Quickshell
import Quickshell.Io
import qs.Core.Services
pragma Singleton

Item {
    id: root

    property var cavaData: []
    readonly property bool isCavaActive: MprisService.isPlaying && SystemInfoService.powerProfile !== "power-saver"

    Timer {
        id: watchdog

        interval: 1000
        repeat: true
        running: root.isCavaActive
        onTriggered: {
            if (root.isCavaActive && !cavaProc.running)
                cavaProc.running = true;

        }
    }

    Process {
        id: cavaProc

        command: ["sh", "-c", "exec cava -p " + Quickshell.shellDir + "/Modules/Music/cava.conf"]
        running: root.isCavaActive
        onRunningChanged: {
            if (!running)
                root.cavaData = [];

        }

        stdout: SplitParser {
            onRead: (data) => {
                let trimmed = data.trim();
                if (!trimmed)
                    return ;

                let parts = trimmed.split(";");
                let vals = [];
                for (let i = 0; i < 36 && i < parts.length; i++) {
                    let val = parseInt(parts[i]);
                    vals.push(isNaN(val) ? 0 : val);
                }
                if (vals.length > 0)
                    root.cavaData = vals;

            }
        }

    }

}
