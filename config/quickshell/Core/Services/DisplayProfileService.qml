import QtQuick
import Quickshell
import Quickshell.Io
import qs.Core.Services
pragma Singleton

Item {
    id: displayProfileService

    property bool nightLightActive: false
    property int nightLightTemperature: 4500
    property bool caffeineActive: false
    property bool gameModeActive: false
    property bool gameModeDaemonDetected: false
    property bool autoActivatedByDaemon: false
    readonly property string gameModeSubtitle: {
        if (!gameModeActive)
            return "Off";

        if (gameModeDaemonDetected)
            return "Playing (gamemoded)";

        return "Max Perf & Scanout";
    }

    function applyNightLight(state) {
        if (state) {
            nightLightProc.command = ["hyprsunset", "-t", displayProfileService.nightLightTemperature.toString()];
            nightLightProc.running = false;
            nightLightProc.running = true;
        } else {
            nightLightProc.running = false;
            pkillSunsetProc.running = false;
            pkillSunsetProc.running = true;
        }
    }

    function applyCaffeine(state) {
        caffeineProc.running = false;
        if (state)
            caffeineProc.running = true;

    }

    function applyGameMode(enable) {
        gameModePwrProc.command = ["python3", Quickshell.shellDir + "/Core/Services/scripts/game_mode.py", enable ? "apply" : "revert"];
        gameModePwrProc.running = false;
        gameModePwrProc.running = true;
        displayProfileService.caffeineActive = enable;
        if (enable) {
            let evalLua = "hl.config({ animations = { enabled = false }, decoration = { rounding = 0, blur = { enabled = false }, shadow = { enabled = false } }, render = { direct_scanout = 1 }, misc = { vrr = 1 } })";
            hyprGameProc.command = ["hyprctl", "eval", evalLua];
            hyprGameProc.running = false;
            hyprGameProc.running = true;
        } else {
            hyprGameProc.command = ["hyprctl", "reload"];
            hyprGameProc.running = false;
            hyprGameProc.running = true;
        }
    }

    onNightLightActiveChanged: {
        if (SettingsService.settingsLoaded)
            SettingsService.saveSettings();

        applyNightLight(nightLightActive);
    }
    onNightLightTemperatureChanged: {
        if (SettingsService.settingsLoaded)
            SettingsService.saveSettings();

        if (nightLightActive)
            applyNightLight(true);

    }
    onCaffeineActiveChanged: {
        if (SettingsService.settingsLoaded)
            SettingsService.saveSettings();

        applyCaffeine(caffeineActive);
    }
    onGameModeActiveChanged: {
        if (SettingsService.settingsLoaded)
            SettingsService.saveSettings();

        applyGameMode(gameModeActive);
    }

    Timer {
        id: gameDaemonPollTimer

        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!checkGameDaemonProc.running)
                checkGameDaemonProc.running = true;

        }
    }

    Process {
        id: checkGameDaemonProc

        command: ["python3", Quickshell.shellDir + "/Core/Services/scripts/game_mode.py", "status"]

        stdout: SplitParser {
            onRead: (data) => {
                if (!data)
                    return ;

                try {
                    let info = JSON.parse(data.trim());
                    if (info.gamemode_active) {
                        displayProfileService.gameModeDaemonDetected = true;
                        if (!displayProfileService.gameModeActive) {
                            displayProfileService.autoActivatedByDaemon = true;
                            displayProfileService.gameModeActive = true;
                        }
                    } else {
                        displayProfileService.gameModeDaemonDetected = false;
                        if (displayProfileService.gameModeActive && displayProfileService.autoActivatedByDaemon) {
                            displayProfileService.autoActivatedByDaemon = false;
                            displayProfileService.gameModeActive = false;
                        }
                    }
                } catch (e) {
                }
            }
        }

    }

    Process {
        id: gameModePwrProc
    }

    Process {
        id: hyprGameProc

        onExited: (code) => {
            if (!displayProfileService.gameModeActive)
                HyprlandService.reloadHyprPrefs();

        }
    }

    Process {
        id: nightLightProc
    }

    Process {
        id: pkillSunsetProc

        command: ["pkill", "hyprsunset"]
    }

    Process {
        id: caffeineProc

        command: ["systemd-inhibit", "--what=idle", "--who=quickshell", "--why=Keep screen active", "--mode=block", "sleep", "infinity"]
    }

}
