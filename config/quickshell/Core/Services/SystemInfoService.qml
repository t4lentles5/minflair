import QtQuick
import Quickshell
import Quickshell.Io
import qs.Core
pragma Singleton

Item {
    id: systemInfoService

    property int performanceInterval: 2000
    property string powerProfile: "balanced"
    property bool hasPerformanceProfile: true
    property date currentTime: systemClock.date
    property string osId: "arch"
    readonly property string osName: {
        switch (osId) {
        case "endeavouros":
            return "EndeavourOS";
        case "manjaro":
        case "manjaro-arm":
            return "Manjaro";
        case "garuda":
            return "Garuda Linux";
        case "arcolinux":
            return "ArcoLinux";
        case "cachyos":
            return "CachyOS";
        case "artix":
            return "Artix Linux";
        default:
            return "Arch Linux";
        }
    }
    property bool hasBattery: true
    property int batteryLevel: 100
    readonly property string batteryPercentage: batteryLevel + "%"
    property string batteryStatus: ""
    property string batteryEstimation: {
        if (!hasBattery)
            return "Continuous power supply active";

        if (batteryStatus === "Charging")
            return "Charging";
        else if (batteryStatus === "Discharging")
            return "Discharging";
        else if (batteryStatus === "Full")
            return "Fully Charged";
        else if (batteryStatus === "Not charging")
            return "Not charging";
        else
            return "Stationary";
    }

    function applyProfile(profile) {
        let targetProfile = profile;
        systemInfoService.powerProfile = targetProfile;
        setPowerProfileProc.running = false;
        setPowerProfileProc.command = ["powerprofilesctl", "set", targetProfile];
        setPowerProfileProc.running = true;
        if (targetProfile === "performance") {
            systemInfoService.performanceInterval = 1000;
            HyprlandService.enableAnimations = true;
            brightnessProc.running = false;
            brightnessProc.command = ["brightnessctl", "s", "100%"];
            brightnessProc.running = true;
            if (SettingsService.settingsLoaded)
                HyprlandService.setPowerSaverMode(false);

        } else if (targetProfile === "power-saver") {
            systemInfoService.performanceInterval = 5000;
            HyprlandService.enableAnimations = false;
            brightnessProc.running = false;
            brightnessProc.command = ["brightnessctl", "s", "15%"];
            brightnessProc.running = true;
            if (SettingsService.settingsLoaded)
                HyprlandService.setPowerSaverMode(true);

            DisplayProfileService.caffeineActive = false;
        } else {
            systemInfoService.performanceInterval = 2000;
            HyprlandService.enableAnimations = true;
            brightnessProc.running = false;
            brightnessProc.command = ["brightnessctl", "s", "75%"];
            brightnessProc.running = true;
            if (SettingsService.settingsLoaded)
                HyprlandService.setPowerSaverMode(false);

        }
        if (SettingsService.settingsLoaded)
            SettingsService.saveSettings();

    }

    onPerformanceIntervalChanged: {
        if (SettingsService.settingsLoaded)
            SettingsService.saveSettings();

    }

    SystemClock {
        id: systemClock

        precision: SettingsService.clockSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }

    Process {
        id: setPowerProfileProc
    }

    Process {
        id: brightnessProc
    }

    Process {
        id: osReleaseProc

        command: ["sh", "-c", "grep '^ID=' /etc/os-release | cut -d '=' -f 2 | tr -d '\"'"]
        running: true
        onExited: (exitCode) => {
            if (exitCode === 0) {
                let id = osOutput.text.trim();
                if (id !== "")
                    systemInfoService.osId = id;

            }
        }

        stdout: StdioCollector {
            id: osOutput
        }

    }

    Process {
        id: batteryProc

        command: ["sh", "-c", 'for b in /sys/class/power_supply/BAT* /sys/class/power_supply/*; do if [ -d "$b" ] && [ -f "$b/capacity" ]; then if [ -f "$b/type" ] && [ "$(cat "$b/type" 2>/dev/null)" != "Battery" ]; then continue; fi; if [ -f "$b/present" ] && [ "$(cat "$b/present" 2>/dev/null)" = "0" ]; then continue; fi; c=$(cat "$b/capacity" 2>/dev/null); s=$(cat "$b/status" 2>/dev/null); [ -z "$s" ] && s="Unknown"; if [ -n "$c" ]; then echo "$c $s"; exit 0; fi; fi; done; echo "0 No battery"']

        stdout: SplitParser {
            onRead: (data) => {
                let parts = data.trim().split(" ");
                if (parts.length >= 2) {
                    let capacity = parseInt(parts[0]);
                    let status = parts.slice(1).join(" ");
                    systemInfoService.batteryLevel = isNaN(capacity) ? 0 : Math.min(100, Math.max(0, capacity));
                    systemInfoService.batteryStatus = status;
                    systemInfoService.hasBattery = (status !== "No battery");
                }
            }
        }

    }

    Timer {
        id: batteryTimer

        interval: systemInfoService.performanceInterval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            batteryProc.running = false;
            batteryProc.running = true;
        }
    }

}
