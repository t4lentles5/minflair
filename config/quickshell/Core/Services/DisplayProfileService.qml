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

        if (gameModeActive) {
            HyprlandService.enableAnimations = false;
            HyprlandService.hyprBlur = false;
            displayProfileService.caffeineActive = true;
        } else {
            HyprlandService.enableAnimations = true;
            HyprlandService.hyprBlur = true;
            displayProfileService.caffeineActive = false;
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
