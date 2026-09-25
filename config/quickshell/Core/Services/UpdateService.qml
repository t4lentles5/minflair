import QtQuick
import Quickshell
import Quickshell.Io
import qs.Core
pragma Singleton

Item {
    id: updateService

    property bool isSystemUpdating: false
    property bool packageManagerChecksEnabled: true
    property int packageManagerCheckInterval: 3.6e+06
    property string pacmanUpdatesCount: "..."
    property string aurUpdatesCount: "..."
    readonly property bool isCheckingUpdates: pacmanProc.running || aurProc.running

    signal checkUpdates()

    onPackageManagerChecksEnabledChanged: {
        if (SettingsService.settingsLoaded)
            SettingsService.saveSettings();

    }
    onPackageManagerCheckIntervalChanged: {
        if (SettingsService.settingsLoaded)
            SettingsService.saveSettings();

    }
    onIsSystemUpdatingChanged: {
        if (!updateService.isSystemUpdating) {
            updateService.pacmanUpdatesCount = "...";
            updateService.aurUpdatesCount = "...";
            checkDelayTimer.start();
        }
    }
    onCheckUpdates: {
        pacmanProc.running = false;
        pacmanProc.running = true;
        aurProc.running = false;
        aurProc.running = true;
    }

    Process {
        id: pacmanProc

        command: ["sh", "-c", "checkupdates | wc -l || echo 0"]

        stdout: SplitParser {
            onRead: (data) => {
                updateService.pacmanUpdatesCount = data.trim();
            }
        }

    }

    Process {
        id: aurProc

        command: ["sh", "-c", "yay -Qua | wc -l || echo 0"]

        stdout: SplitParser {
            onRead: (data) => {
                updateService.aurUpdatesCount = data.trim();
            }
        }

    }

    Process {
        id: checkLockProc

        command: ["test", "-f", "/var/lib/pacman/db.lck"]
        onExited: (code) => {
            updateService.isSystemUpdating = (code === 0);
        }
    }

    Timer {
        id: lockCheckTimer

        interval: updateService.isSystemUpdating || AppState.activePopup === "packageManager" ? 1500 : 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            checkLockProc.running = true;
        }
    }

    Timer {
        id: hourlyUpdateTimer

        interval: updateService.packageManagerCheckInterval
        running: updateService.packageManagerChecksEnabled
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            pacmanProc.running = false;
            pacmanProc.running = true;
            aurProc.running = false;
            aurProc.running = true;
        }
    }

    Timer {
        id: checkDelayTimer

        interval: 800
        repeat: false
        onTriggered: {
            pacmanProc.running = false;
            pacmanProc.running = true;
            aurProc.running = false;
            aurProc.running = true;
        }
    }

}
