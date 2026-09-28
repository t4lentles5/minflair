import QtQuick
import Quickshell
import Quickshell.Io
import qs.Core
pragma Singleton

Item {
    id: settingsService

    property bool settingsLoaded: false
    property string packageManagerMode: "install"
    property int clipboardMaxItems: 100
    property var enabledKbLayouts: ["us", "latam"]
    property string githubUsername: ""
    property string githubToken: ""
    property string musicPlayer: "none"
    property string musicPlayerCommand: ""
    property bool isSettingsLoading: settingsLoader.running
    property string quoteCategory: "All"
    property string fontFamily: "Geist"
    property real fontScale: 1
    property real hyprScale: 1
    property bool clock24h: true
    property bool clockSeconds: false
    property bool clockShowDate: true
    property string cursorTheme: "Bibata-Modern-Classic"
    property int cursorSize: 24
    property string barStyle: "minflair"
    property bool barMinflairMode: barStyle === "minflair"
    property bool barFramedMode: barStyle === "framed"
    property bool barIslandMode: barStyle === "island"
    property bool barNotchMode: barStyle === "notch"
    property bool barConvexMode: barStyle === "convex"
    property bool barCompactMode: false
    readonly property bool isBarCompact: barCompactMode && barConvexMode
    property bool barIslandExpanded: false
    property bool barNotchExpanded: false
    property string barSlotL1: "workspaces"
    property string barSlotL2: "none"
    property string barSlotL3: "none"
    property string barSlotC1: "clock"
    property string barSlotC2: "media"
    property string barSlotR1: "recording"
    property string barSlotR2: "control_center"
    property string barSlotR3: "tray"
    readonly property int barWidgetHeight: (barIslandMode || barNotchMode || isBarCompact) ? 28 : 32

    function saveSettings() {
        saveTimer.restart();
    }

    function load() {
        if (!settingsLoaded && !isSettingsLoading)
            settingsLoader.running = true;

    }

    function applyCursor(theme, size) {
        let t = theme !== undefined ? theme : cursorTheme;
        let s = size !== undefined ? size : cursorSize;
        applyCursorProc.command = ["python3", Quickshell.shellDir + "/Scripts/theme/apply_cursor.py", t, s.toString()];
        applyCursorProc.running = false;
        applyCursorProc.running = true;
    }

    function applyFont(font, size) {
        let f = font !== undefined ? font : fontFamily;
        let s = size !== undefined ? size : Math.round(11 * fontScale);
        applyFontProc.command = ["python3", Quickshell.shellDir + "/Scripts/theme/apply_font.py", f, s.toString()];
        applyFontProc.running = false;
        applyFontProc.running = true;
    }

    Component.onCompleted: {
        load();
    }
    onClipboardMaxItemsChanged: {
        if (settingsLoaded)
            saveSettings();

    }
    onEnabledKbLayoutsChanged: {
        if (settingsLoaded)
            saveSettings();

    }
    onGithubUsernameChanged: {
        if (settingsLoaded)
            saveSettings();

    }
    onGithubTokenChanged: {
        if (settingsLoaded)
            saveSettings();

    }
    onMusicPlayerChanged: {
        if (settingsLoaded)
            saveSettings();

    }
    onMusicPlayerCommandChanged: {
        if (settingsLoaded)
            saveSettings();

    }
    onQuoteCategoryChanged: {
        if (settingsLoaded)
            saveSettings();

    }
    onFontFamilyChanged: {
        if (settingsLoaded) {
            saveSettings();
            applyFont(fontFamily, Math.round(11 * fontScale));
        }
    }
    onFontScaleChanged: {
        if (settingsLoaded) {
            saveSettings();
            applyFont(fontFamily, Math.round(11 * fontScale));
        }
    }
    onHyprScaleChanged: {
        if (settingsLoaded)
            saveSettings();

    }
    onClock24hChanged: {
        if (settingsLoaded)
            saveSettings();

    }
    onClockSecondsChanged: {
        if (settingsLoaded)
            saveSettings();

    }
    onClockShowDateChanged: {
        if (settingsLoaded)
            saveSettings();

    }
    onCursorThemeChanged: {
        if (settingsLoaded) {
            saveSettings();
            applyCursor(cursorTheme, cursorSize);
        }
    }
    onCursorSizeChanged: {
        if (settingsLoaded) {
            saveSettings();
            applyCursor(cursorTheme, cursorSize);
        }
    }
    onBarStyleChanged: {
        if (settingsLoaded)
            saveSettings();

    }
    onBarCompactModeChanged: {
        if (settingsLoaded)
            saveSettings();

    }
    onBarIslandExpandedChanged: {
        if (settingsLoaded)
            saveSettings();

    }
    onBarNotchExpandedChanged: {
        if (settingsLoaded)
            saveSettings();

    }
    onBarSlotL1Changed: {
        if (settingsLoaded)
            saveSettings();

    }
    onBarSlotL2Changed: {
        if (settingsLoaded)
            saveSettings();

    }
    onBarSlotL3Changed: {
        if (settingsLoaded)
            saveSettings();

    }
    onBarSlotC1Changed: {
        if (settingsLoaded)
            saveSettings();

    }
    onBarSlotC2Changed: {
        if (settingsLoaded)
            saveSettings();

    }
    onBarSlotR1Changed: {
        if (settingsLoaded)
            saveSettings();

    }
    onBarSlotR2Changed: {
        if (settingsLoaded)
            saveSettings();

    }
    onBarSlotR3Changed: {
        if (settingsLoaded)
            saveSettings();

    }

    Timer {
        id: saveTimer

        interval: 100
        repeat: false
        onTriggered: {
            let data = {
                "performanceInterval": SystemInfoService.performanceInterval,
                "powerProfile": SystemInfoService.powerProfile,
                "packageManagerChecksEnabled": UpdateService.packageManagerChecksEnabled,
                "packageManagerCheckInterval": UpdateService.packageManagerCheckInterval,
                "clipboardMaxItems": settingsService.clipboardMaxItems,
                "enabledKbLayouts": settingsService.enabledKbLayouts,
                "animationSpeedFactor": HyprlandService.animationSpeedFactor,
                "githubUsername": settingsService.githubUsername,
                "githubToken": settingsService.githubToken,
                "musicPlayer": settingsService.musicPlayer,
                "musicPlayerCommand": settingsService.musicPlayerCommand,
                "nightLightActive": DisplayProfileService.nightLightActive,
                "caffeineActive": DisplayProfileService.caffeineActive,
                "gameModeActive": DisplayProfileService.gameModeActive,
                "keyboardLayout": HyprlandService.keyboardLayout,
                "wpAutoShuffle": HyprlandService.wpAutoShuffle,
                "wpShuffleInterval": HyprlandService.wpShuffleInterval,
                "wpEnableTransitions": HyprlandService.wpEnableTransitions,
                "wpTransitionType": HyprlandService.wpTransitionType,
                "wpTransitionPos": HyprlandService.wpTransitionPos,
                "wpTransitionStep": HyprlandService.wpTransitionStep,
                "wpTransitionFps": HyprlandService.wpTransitionFps,
                "wpTransitionAngle": HyprlandService.wpTransitionAngle,
                "micMuted": AudioService.micMuted,
                "micVolume": AudioService.micVolume,
                "quoteCategory": settingsService.quoteCategory,
                "fontFamily": settingsService.fontFamily,
                "fontScale": settingsService.fontScale,
                "hyprScale": settingsService.hyprScale,
                "clock24h": settingsService.clock24h,
                "clockSeconds": settingsService.clockSeconds,
                "clockShowDate": settingsService.clockShowDate,
                "cursorTheme": settingsService.cursorTheme,
                "cursorSize": settingsService.cursorSize,
                "barStyle": settingsService.barStyle,
                "barFramedMode": settingsService.barFramedMode,
                "barCompactMode": settingsService.barCompactMode,
                "barIslandExpanded": settingsService.barIslandExpanded,
                "barNotchExpanded": settingsService.barNotchExpanded,
                "barSlotL1": settingsService.barSlotL1,
                "barSlotL2": settingsService.barSlotL2,
                "barSlotL3": settingsService.barSlotL3,
                "barSlotC1": settingsService.barSlotC1,
                "barSlotC2": settingsService.barSlotC2,
                "barSlotR1": settingsService.barSlotR1,
                "barSlotR2": settingsService.barSlotR2,
                "barSlotR3": settingsService.barSlotR3
            };
            settingsSaver.command = ["sh", "-c", "mkdir -p ~/.cache/quickshell && cat << 'EOF' > ~/.cache/quickshell/settings_prefs.json\n" + JSON.stringify(data) + "\nEOF"];
            settingsSaver.running = true;
        }
    }

    Process {
        id: settingsLoader

        command: ["cat", Quickshell.env("HOME") + "/.cache/quickshell/settings_prefs.json"]
        onExited: function(exitCode) {
            if (exitCode !== 0) {
                SystemInfoService.applyProfile("balanced");
                settingsService.saveSettings();
                settingsService.settingsLoaded = true;
                HyprlandService.triggerStartupTimer();
                settingsService.applyCursor(settingsService.cursorTheme, settingsService.cursorSize);
                settingsService.applyFont(settingsService.fontFamily, Math.round(11 * settingsService.fontScale));
            }
        }

        stdout: SplitParser {
            onRead: (data) => {
                if (data && data.trim() !== "") {
                    try {
                        let prefs = JSON.parse(data.trim());
                        if (prefs.powerProfile !== undefined) {
                            SystemInfoService.powerProfile = prefs.powerProfile;
                            SystemInfoService.applyProfile(prefs.powerProfile);
                        } else {
                            SystemInfoService.applyProfile("balanced");
                        }
                        if (prefs.performanceInterval !== undefined)
                            SystemInfoService.performanceInterval = prefs.performanceInterval;

                        if (prefs.packageManagerChecksEnabled !== undefined)
                            UpdateService.packageManagerChecksEnabled = prefs.packageManagerChecksEnabled;

                        if (prefs.packageManagerCheckInterval !== undefined)
                            UpdateService.packageManagerCheckInterval = prefs.packageManagerCheckInterval;

                        if (prefs.clipboardMaxItems !== undefined)
                            settingsService.clipboardMaxItems = prefs.clipboardMaxItems;

                        if (prefs.animationSpeedFactor !== undefined)
                            HyprlandService.animationSpeedFactor = prefs.animationSpeedFactor;

                        if (prefs.githubUsername !== undefined)
                            settingsService.githubUsername = prefs.githubUsername;

                        if (prefs.githubToken !== undefined)
                            settingsService.githubToken = prefs.githubToken;

                        if (prefs.musicPlayer !== undefined)
                            settingsService.musicPlayer = prefs.musicPlayer;

                        if (prefs.musicPlayerCommand !== undefined)
                            settingsService.musicPlayerCommand = prefs.musicPlayerCommand;

                        if (prefs.nightLightActive !== undefined)
                            DisplayProfileService.nightLightActive = prefs.nightLightActive;

                        if (prefs.caffeineActive !== undefined)
                            DisplayProfileService.caffeineActive = prefs.caffeineActive;

                        if (prefs.gameModeActive !== undefined)
                            DisplayProfileService.gameModeActive = prefs.gameModeActive;

                        if (prefs.keyboardLayout !== undefined)
                            HyprlandService.keyboardLayout = prefs.keyboardLayout;

                        if (prefs.enabledKbLayouts !== undefined)
                            settingsService.enabledKbLayouts = prefs.enabledKbLayouts;

                        if (prefs.wpAutoShuffle !== undefined)
                            HyprlandService.wpAutoShuffle = prefs.wpAutoShuffle;

                        if (prefs.wpShuffleInterval !== undefined)
                            HyprlandService.wpShuffleInterval = prefs.wpShuffleInterval;

                        if (prefs.wpEnableTransitions !== undefined)
                            HyprlandService.wpEnableTransitions = prefs.wpEnableTransitions;

                        if (prefs.wpTransitionType !== undefined)
                            HyprlandService.wpTransitionType = prefs.wpTransitionType;

                        if (prefs.wpTransitionPos !== undefined)
                            HyprlandService.wpTransitionPos = prefs.wpTransitionPos;

                        if (prefs.wpTransitionStep !== undefined)
                            HyprlandService.wpTransitionStep = prefs.wpTransitionStep;

                        if (prefs.wpTransitionFps !== undefined)
                            HyprlandService.wpTransitionFps = prefs.wpTransitionFps;

                        if (prefs.wpTransitionAngle !== undefined)
                            HyprlandService.wpTransitionAngle = prefs.wpTransitionAngle;

                        if (prefs.micVolume !== undefined) {
                            AudioService.micVolume = AudioService.hasPhysicalMic ? prefs.micVolume : 0;
                            if (AudioService.hasPhysicalMic)
                                AudioService.setMicVolume(prefs.micVolume);

                        }
                        if (prefs.micMuted !== undefined) {
                            AudioService.micMuted = AudioService.hasPhysicalMic ? prefs.micMuted : true;
                            if (AudioService.hasPhysicalMic)
                                AudioService.setMicMuted(prefs.micMuted);

                        }
                        if (prefs.quoteCategory !== undefined)
                            settingsService.quoteCategory = prefs.quoteCategory;

                        if (prefs.fontFamily !== undefined)
                            settingsService.fontFamily = prefs.fontFamily;

                        if (prefs.fontScale !== undefined)
                            settingsService.fontScale = prefs.fontScale;

                        if (prefs.hyprScale !== undefined) {
                            settingsService.hyprScale = prefs.hyprScale;
                            hyprScaleApplyProc.running = true;
                        }
                        if (prefs.clock24h !== undefined)
                            settingsService.clock24h = prefs.clock24h;

                        if (prefs.clockSeconds !== undefined)
                            settingsService.clockSeconds = prefs.clockSeconds;

                        if (prefs.clockShowDate !== undefined)
                            settingsService.clockShowDate = prefs.clockShowDate;

                        if (prefs.cursorTheme !== undefined)
                            settingsService.cursorTheme = prefs.cursorTheme;

                        if (prefs.cursorSize !== undefined)
                            settingsService.cursorSize = prefs.cursorSize;

                        applyCursor(settingsService.cursorTheme, settingsService.cursorSize);
                        applyFont(settingsService.fontFamily, Math.round(11 * settingsService.fontScale));
                        if (prefs.barStyle !== undefined)
                            settingsService.barStyle = prefs.barStyle === "floating" ? "minflair" : prefs.barStyle;
                        else if (prefs.barFramedMode !== undefined)
                            settingsService.barStyle = prefs.barFramedMode ? "framed" : "minflair";
                        if (prefs.barCompactMode !== undefined)
                            settingsService.barCompactMode = prefs.barCompactMode;

                        if (prefs.barIslandExpanded !== undefined)
                            settingsService.barIslandExpanded = prefs.barIslandExpanded;

                        if (prefs.barNotchExpanded !== undefined)
                            settingsService.barNotchExpanded = prefs.barNotchExpanded;

                        if (prefs.barSlotL1 !== undefined)
                            settingsService.barSlotL1 = prefs.barSlotL1;

                        if (prefs.barSlotL2 !== undefined)
                            settingsService.barSlotL2 = prefs.barSlotL2;

                        if (prefs.barSlotL3 !== undefined)
                            settingsService.barSlotL3 = prefs.barSlotL3;

                        if (prefs.barSlotC1 !== undefined)
                            settingsService.barSlotC1 = prefs.barSlotC1;

                        if (prefs.barSlotC2 !== undefined)
                            settingsService.barSlotC2 = prefs.barSlotC2;

                        if (prefs.barSlotR1 !== undefined)
                            settingsService.barSlotR1 = prefs.barSlotR1;

                        if (prefs.barSlotR2 !== undefined)
                            settingsService.barSlotR2 = prefs.barSlotR2;

                        if (prefs.barSlotR3 !== undefined)
                            settingsService.barSlotR3 = prefs.barSlotR3;

                    } catch (e) {
                        console.error("Error loading settings: " + e);
                        SystemInfoService.applyProfile("balanced");
                    }
                }
                settingsService.settingsLoaded = true;
                HyprlandService.triggerStartupTimer();
            }
        }

    }

    Process {
        id: settingsSaver
    }

    Process {
        id: hyprScaleApplyProc

        command: ["sh", "-c", Quickshell.shellDir + "/Scripts/system/hypr_scale.sh " + settingsService.hyprScale]
    }

    Process {
        id: applyCursorProc
    }

    Process {
        id: applyFontProc
    }

}
