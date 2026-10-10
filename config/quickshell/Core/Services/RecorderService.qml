import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

Singleton {
    id: root

    property bool running: false
    property int durationInSeconds: 0

    function formattedTime() {
        let m = Math.floor(durationInSeconds / 60);
        let s = durationInSeconds % 60;
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    function toggle(args) {
        if (args === undefined)
            args = [];

        let cmd = [Quickshell.shellDir + "/Modules/ScreenCapture/scripts/record.sh"].concat(args);
        Quickshell.execDetached(cmd);
        checkDelay.restart();
    }

    onRunningChanged: {
        if (!running) {
            durationInSeconds = 0;
            durationTimer.stop();
        } else {
            durationInSeconds = 0;
            durationTimer.start();
        }
    }

    Timer {
        id: durationTimer

        interval: 1000
        repeat: true
        onTriggered: root.durationInSeconds++
    }

    Timer {
        id: checkTimer

        interval: root.running ? 1000 : 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!checkProc.running)
                checkProc.running = true;

        }
    }

    Timer {
        id: checkDelay

        interval: 300
        repeat: false
        onTriggered: {
            if (!checkProc.running)
                checkProc.running = true;

        }
    }

    Process {
        id: checkProc

        command: ["pidof", "wf-recorder"]
        onExited: (code) => {
            root.running = (code === 0);
        }
    }

}
