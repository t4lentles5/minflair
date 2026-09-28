import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Core
pragma Singleton

Item {
    id: hyprlandService

    property bool enableAnimations: true
    property real animationSpeedFactor: 1
    property string keyboardLayout: "us"
    property bool wpAutoShuffle: false
    property int wpShuffleInterval: 10
    property bool wpEnableTransitions: true
    property string wpTransitionType: "grow"
    property string wpTransitionPos: "center"
    property int wpTransitionStep: 120
    property int wpTransitionFps: 60
    property int wpTransitionAngle: 30
    property bool hyprBlur: true
    property int hyprRounding: 32
    property int hyprActiveOpacity: 100
    property int hyprInactiveOpacity: 100
    property int hyprBlurSize: 6
    property int hyprBlurPasses: 4
    property int hyprGapsIn: 4
    property int hyprGapsOut: 8
    property int hyprBorderSize: 0
    property bool hyprShadow: true
    property int hyprShadowRange: 8
    property int hyprShadowRenderPower: 3
    property bool hyprPrefsLoaded: false
    property bool isSyncing: false
    property bool isTrueFullscreen: false

    function checkFullscreen() {
        if (checkFullscreenProc.running)
            checkFullscreenProc.running = false;

        checkFullscreenProc.running = true;
    }

    function applyHyprlandSettings() {
        if (!hyprPrefsLoaded || isSyncing)
            return ;

        applySettingsTimer.restart();
    }

    function setPowerSaverMode(enabled) {
        animationsProc.running = false;
        if (enabled) {
            let jsonArgs = {
                "animations": {
                    "enabled": false
                },
                "decoration": {
                    "rounding": 0,
                    "blur": {
                        "enabled": false
                    },
                    "shadow": {
                        "enabled": false
                    }
                }
            };
            animationsProc.command = ["python3", Quickshell.shellDir + "/Core/Services/scripts/update_hypr_prefs.py", JSON.stringify(jsonArgs)];
            animationsProc.running = true;
        } else {
            applyHyprlandSettings();
        }
    }

    function startupAnimations() {
    }

    function triggerStartupTimer() {
        startupApplyTimer.start();
    }

    onEnableAnimationsChanged: {
        if (SettingsService.settingsLoaded && hyprPrefsLoaded && !isSyncing) {
            animationsProc.running = false;
            animationsProc.command = ["hyprctl", "eval", "hl.config({ animations = { enabled = " + (enableAnimations ? "true" : "false") + " } })"];
            animationsProc.running = true;
            let jsonArgs = {
                "animations": {
                    "enabled": enableAnimations
                }
            };
            patchUserPrefsProc.command = ["python3", Quickshell.shellDir + "/Core/Services/scripts/update_hypr_prefs.py", JSON.stringify(jsonArgs)];
            patchUserPrefsProc.running = false;
            patchUserPrefsProc.running = true;
        }
    }
    onAnimationSpeedFactorChanged: {
        if (SettingsService.settingsLoaded)
            SettingsService.saveSettings();

    }
    onWpAutoShuffleChanged: {
        if (SettingsService.settingsLoaded)
            SettingsService.saveSettings();

    }
    onWpShuffleIntervalChanged: {
        if (SettingsService.settingsLoaded)
            SettingsService.saveSettings();

    }
    onWpEnableTransitionsChanged: {
        if (SettingsService.settingsLoaded)
            SettingsService.saveSettings();

    }
    onWpTransitionTypeChanged: {
        if (SettingsService.settingsLoaded)
            SettingsService.saveSettings();

    }
    onWpTransitionPosChanged: {
        if (SettingsService.settingsLoaded)
            SettingsService.saveSettings();

    }
    onWpTransitionStepChanged: {
        if (SettingsService.settingsLoaded)
            SettingsService.saveSettings();

    }
    onWpTransitionFpsChanged: {
        if (SettingsService.settingsLoaded)
            SettingsService.saveSettings();

    }
    onWpTransitionAngleChanged: {
        if (SettingsService.settingsLoaded)
            SettingsService.saveSettings();

    }
    onKeyboardLayoutChanged: {
        if (SettingsService.settingsLoaded) {
            SettingsService.saveSettings();
            changeLayoutProc.command = ["hyprctl", "eval", "hl.config({ input = { kb_layout = '" + keyboardLayout + "' } })"];
            changeLayoutProc.running = false;
            changeLayoutProc.running = true;
        }
    }
    onHyprBlurChanged: {
        if (hyprPrefsLoaded && !isSyncing)
            applyHyprlandSettings();

    }
    onHyprRoundingChanged: {
        if (hyprPrefsLoaded && !isSyncing)
            applyHyprlandSettings();

    }
    onHyprActiveOpacityChanged: {
        if (hyprPrefsLoaded && !isSyncing)
            applyHyprlandSettings();

    }
    onHyprInactiveOpacityChanged: {
        if (hyprPrefsLoaded && !isSyncing)
            applyHyprlandSettings();

    }
    onHyprBlurSizeChanged: {
        if (hyprPrefsLoaded && !isSyncing)
            applyHyprlandSettings();

    }
    onHyprBlurPassesChanged: {
        if (hyprPrefsLoaded && !isSyncing)
            applyHyprlandSettings();

    }
    onHyprGapsInChanged: {
        if (hyprPrefsLoaded && !isSyncing)
            applyHyprlandSettings();

    }
    onHyprGapsOutChanged: {
        if (hyprPrefsLoaded && !isSyncing)
            applyHyprlandSettings();

    }
    onHyprBorderSizeChanged: {
        if (hyprPrefsLoaded && !isSyncing)
            applyHyprlandSettings();

    }
    onHyprShadowChanged: {
        if (hyprPrefsLoaded && !isSyncing)
            applyHyprlandSettings();

    }
    onHyprShadowRangeChanged: {
        if (hyprPrefsLoaded && !isSyncing)
            applyHyprlandSettings();

    }
    onHyprShadowRenderPowerChanged: {
        if (hyprPrefsLoaded && !isSyncing)
            applyHyprlandSettings();

    }
    Component.onCompleted: {
        readHyprPrefsProc.running = true;
        checkFullscreen();
    }

    Timer {
        id: applySettingsTimer

        interval: 50
        repeat: false
        onTriggered: {
            if (!hyprPrefsLoaded || isSyncing)
                return ;

            let ao = (hyprActiveOpacity / 100).toFixed(2);
            let io = (hyprInactiveOpacity / 100).toFixed(2);
            let jsonArgs = {
                "animations": {
                    "enabled": enableAnimations
                },
                "general": {
                    "gaps_in": hyprGapsIn,
                    "gaps_out": hyprGapsOut,
                    "border_size": hyprBorderSize
                },
                "decoration": {
                    "rounding": hyprRounding,
                    "active_opacity": parseFloat(ao),
                    "inactive_opacity": parseFloat(io),
                    "blur": {
                        "enabled": hyprBlur,
                        "size": hyprBlurSize,
                        "passes": hyprBlurPasses
                    },
                    "shadow": {
                        "enabled": hyprShadow,
                        "range": hyprShadowRange,
                        "render_power": hyprShadowRenderPower
                    }
                }
            };
            patchUserPrefsProc.command = ["python3", Quickshell.shellDir + "/Core/Services/scripts/update_hypr_prefs.py", JSON.stringify(jsonArgs)];
            patchUserPrefsProc.running = false;
            patchUserPrefsProc.running = true;
        }
    }

    Timer {
        id: startupApplyTimer

        interval: 1000
        running: false
        repeat: false
        onTriggered: {
            changeLayoutProc.command = ["hyprctl", "eval", "hl.config({ input = { kb_layout = '" + hyprlandService.keyboardLayout + "' } })"];
            changeLayoutProc.running = false;
            changeLayoutProc.running = true;
        }
    }

    Process {
        id: animationsProc
    }

    Process {
        id: changeLayoutProc
    }

    Process {
        id: patchUserPrefsProc
    }

    Process {
        id: checkFullscreenProc

        command: ["sh", "-c", "hyprctl activewindow -j 2>/dev/null | jq -r '(.fullscreen == 2) // false' 2>/dev/null"]

        stdout: SplitParser {
            onRead: (data) => {
                if (!data)
                    return ;

                hyprlandService.isTrueFullscreen = (data.trim() === "true");
            }
        }

    }

    Connections {
        function onRawEvent(event) {
            if (event.name === "activelayout") {
                activeLayoutProc.running = true;
            } else if (event.name === "fullscreen") {
                if (event.data === "0")
                    hyprlandService.isTrueFullscreen = false;
                else
                    hyprlandService.checkFullscreen();
            } else if (event.name === "activewindow" || event.name === "activewindowv2" || event.name === "workspace" || event.name === "workspacev2") {
                hyprlandService.checkFullscreen();
            }
        }

        target: Hyprland
    }

    Process {
        id: activeLayoutProc

        command: ["sh", "-c", "hyprctl devices -j | jq -r '(.keyboards | (map(select(.main == true))[0] // .[0])) | .active_keymap'"]

        stdout: SplitParser {
            onRead: (data) => {
                if (!data)
                    return ;

                let raw = data.trim();
                let code = "us";
                // Map Hyprland full layout names to XKB codes
                const layoutMap = {
                    "English": "us",
                    "Spanish": "latam",
                    "Spanish (Latin American)": "latam",
                    "Spanish (Spain)": "es",
                    "French": "fr",
                    "German": "de",
                    "Italian": "it",
                    "Portuguese": "pt",
                    "Russian": "ru"
                };
                // Try exact match first
                if (layoutMap[raw] !== undefined) {
                    code = layoutMap[raw];
                } else {
                    // Try partial match (e.g. "English (US)")
                    let matched = false;
                    for (let key of Object.keys(layoutMap)) {
                        if (raw.includes(key)) {
                            code = layoutMap[key];
                            matched = true;
                            break;
                        }
                    }
                    if (!matched)
                        code = raw.toLowerCase().split(" ")[0];

                }
                if (hyprlandService.keyboardLayout !== code)
                    hyprlandService.keyboardLayout = code;

            }
        }

    }

    Process {
        id: readHyprPrefsProc

        command: ["python3", Quickshell.shellDir + "/Core/Services/scripts/read_hypr_prefs.py"]
        onExited: (code) => {
            hyprlandService.isSyncing = false;
            hyprlandService.hyprPrefsLoaded = true;
        }

        stdout: SplitParser {
            onRead: (data) => {
                if (data && data.trim() !== "") {
                    try {
                        let prefs = JSON.parse(data.trim());
                        hyprlandService.isSyncing = true;
                        if (prefs["decoration:blur:enabled"] !== undefined)
                            hyprBlur = prefs["decoration:blur:enabled"];

                        if (prefs["decoration:rounding"] !== undefined)
                            hyprRounding = prefs["decoration:rounding"];

                        if (prefs["decoration:active_opacity"] !== undefined)
                            hyprActiveOpacity = Math.round(prefs["decoration:active_opacity"] * 100);

                        if (prefs["decoration:inactive_opacity"] !== undefined)
                            hyprInactiveOpacity = Math.round(prefs["decoration:inactive_opacity"] * 100);

                        if (prefs["decoration:blur:size"] !== undefined)
                            hyprBlurSize = prefs["decoration:blur:size"];

                        if (prefs["decoration:blur:passes"] !== undefined)
                            hyprBlurPasses = prefs["decoration:blur:passes"];

                        if (prefs["general:gaps_in"] !== undefined)
                            hyprGapsIn = prefs["general:gaps_in"];

                        if (prefs["general:gaps_out"] !== undefined)
                            hyprGapsOut = prefs["general:gaps_out"];

                        if (prefs["general:border_size"] !== undefined)
                            hyprBorderSize = prefs["general:border_size"];

                        if (prefs["decoration:shadow:enabled"] !== undefined)
                            hyprShadow = prefs["decoration:shadow:enabled"];

                        if (prefs["decoration:shadow:range"] !== undefined)
                            hyprShadowRange = prefs["decoration:shadow:range"];

                        if (prefs["decoration:shadow:render_power"] !== undefined)
                            hyprShadowRenderPower = prefs["decoration:shadow:render_power"];

                        if (prefs["animations:enabled"] !== undefined)
                            enableAnimations = prefs["animations:enabled"];

                    } catch (e) {
                        console.error("Error parsing hypr prefs: " + e);
                    } finally {
                        let prefs = JSON.parse(data.trim());
                        hyprlandService.isSyncing = true;
                        if (prefs["decoration:blur:enabled"] !== undefined)
                            hyprBlur = prefs["decoration:blur:enabled"];

                        if (prefs["decoration:rounding"] !== undefined)
                            hyprRounding = prefs["decoration:rounding"];

                        if (prefs["decoration:active_opacity"] !== undefined)
                            hyprActiveOpacity = Math.round(prefs["decoration:active_opacity"] * 100);

                        if (prefs["decoration:inactive_opacity"] !== undefined)
                            hyprInactiveOpacity = Math.round(prefs["decoration:inactive_opacity"] * 100);

                        if (prefs["decoration:blur:size"] !== undefined)
                            hyprBlurSize = prefs["decoration:blur:size"];

                        if (prefs["decoration:blur:passes"] !== undefined)
                            hyprBlurPasses = prefs["decoration:blur:passes"];

                        if (prefs["general:gaps_in"] !== undefined)
                            hyprGapsIn = prefs["general:gaps_in"];

                        if (prefs["general:gaps_out"] !== undefined)
                            hyprGapsOut = prefs["general:gaps_out"];

                        if (prefs["general:border_size"] !== undefined)
                            hyprBorderSize = prefs["general:border_size"];

                        if (prefs["decoration:shadow:enabled"] !== undefined)
                            hyprShadow = prefs["decoration:shadow:enabled"];

                        if (prefs["decoration:shadow:range"] !== undefined)
                            hyprShadowRange = prefs["decoration:shadow:range"];

                        if (prefs["decoration:shadow:render_power"] !== undefined)
                            hyprShadowRenderPower = prefs["decoration:shadow:render_power"];

                        if (prefs["animations:enabled"] !== undefined)
                            enableAnimations = prefs["animations:enabled"];

                    }
                }
            }
        }

    }

}
