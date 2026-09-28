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
    property real mouseSensitivity: 0
    property string mouseAccelProfile: "flat"
    property bool mouseNaturalScroll: false
    property real mouseScrollFactor: 1
    property bool mouseLeftHanded: false
    property int mouseFollowMouse: 1
    property int cursorInactiveTimeout: 5
    property bool cursorNoWarps: false
    property bool touchpadNaturalScroll: true
    property bool touchpadTapToClick: true
    property bool touchpadDisableWhileTyping: true
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

    function applyMouseSettings() {
        if (!hyprPrefsLoaded || isSyncing)
            return ;

        applyMouseSettingsTimer.restart();
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
    onMouseSensitivityChanged: {
        if (hyprPrefsLoaded && !isSyncing)
            applyMouseSettings();

    }
    onMouseAccelProfileChanged: {
        if (hyprPrefsLoaded && !isSyncing)
            applyMouseSettings();

    }
    onMouseNaturalScrollChanged: {
        if (hyprPrefsLoaded && !isSyncing)
            applyMouseSettings();

    }
    onMouseScrollFactorChanged: {
        if (hyprPrefsLoaded && !isSyncing)
            applyMouseSettings();

    }
    onMouseLeftHandedChanged: {
        if (hyprPrefsLoaded && !isSyncing)
            applyMouseSettings();

    }
    onMouseFollowMouseChanged: {
        if (hyprPrefsLoaded && !isSyncing)
            applyMouseSettings();

    }
    onCursorInactiveTimeoutChanged: {
        if (hyprPrefsLoaded && !isSyncing)
            applyMouseSettings();

    }
    onCursorNoWarpsChanged: {
        if (hyprPrefsLoaded && !isSyncing)
            applyMouseSettings();

    }
    onTouchpadNaturalScrollChanged: {
        if (hyprPrefsLoaded && !isSyncing)
            applyMouseSettings();

    }
    onTouchpadTapToClickChanged: {
        if (hyprPrefsLoaded && !isSyncing)
            applyMouseSettings();

    }
    onTouchpadDisableWhileTypingChanged: {
        if (hyprPrefsLoaded && !isSyncing)
            applyMouseSettings();

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
        id: applyMouseSettingsTimer

        interval: 100
        repeat: false
        onTriggered: {
            if (!hyprPrefsLoaded || isSyncing)
                return ;

            let evalCmd = "hl.config({ " + "input = { " + "sensitivity = " + mouseSensitivity.toFixed(2) + ", " + (mouseAccelProfile !== "" ? "accel_profile = '" + mouseAccelProfile + "', " : "") + "natural_scroll = " + (mouseNaturalScroll ? "true" : "false") + ", " + "scroll_factor = " + mouseScrollFactor.toFixed(2) + ", " + "left_handed = " + (mouseLeftHanded ? "true" : "false") + ", " + "follow_mouse = " + mouseFollowMouse + ", " + "touchpad = { " + "natural_scroll = " + (touchpadNaturalScroll ? "true" : "false") + ", " + "tap_to_click = " + (touchpadTapToClick ? "true" : "false") + ", " + "disable_while_typing = " + (touchpadDisableWhileTyping ? "true" : "false") + "} " + "}, " + "cursor = { " + "inactive_timeout = " + cursorInactiveTimeout + ", " + "no_warps = " + (cursorNoWarps ? "true" : "false") + "} " + "})";
            mouseApplyProc.command = ["hyprctl", "eval", evalCmd];
            mouseApplyProc.running = false;
            mouseApplyProc.running = true;
            let jsonArgs = {
                "input": {
                    "sensitivity": parseFloat(mouseSensitivity.toFixed(2)),
                    "accel_profile": mouseAccelProfile,
                    "natural_scroll": mouseNaturalScroll,
                    "scroll_factor": parseFloat(mouseScrollFactor.toFixed(2)),
                    "left_handed": mouseLeftHanded,
                    "follow_mouse": mouseFollowMouse,
                    "touchpad": {
                        "natural_scroll": touchpadNaturalScroll,
                        "tap_to_click": touchpadTapToClick,
                        "disable_while_typing": touchpadDisableWhileTyping
                    }
                },
                "cursor": {
                    "inactive_timeout": cursorInactiveTimeout,
                    "no_warps": cursorNoWarps
                }
            };
            patchUserPrefsProc.command = ["python3", Quickshell.shellDir + "/Core/Services/scripts/update_hypr_prefs.py", JSON.stringify(jsonArgs)];
            patchUserPrefsProc.running = false;
            patchUserPrefsProc.running = true;
        }
    }

    Process {
        id: mouseApplyProc
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

                        if (prefs["input:sensitivity"] !== undefined)
                            mouseSensitivity = prefs["input:sensitivity"];

                        if (prefs["input:accel_profile"] !== undefined && prefs["input:accel_profile"] !== "[[EMPTY]]")
                            mouseAccelProfile = prefs["input:accel_profile"];

                        if (prefs["input:natural_scroll"] !== undefined)
                            mouseNaturalScroll = prefs["input:natural_scroll"];

                        if (prefs["input:scroll_factor"] !== undefined)
                            mouseScrollFactor = prefs["input:scroll_factor"];

                        if (prefs["input:left_handed"] !== undefined)
                            mouseLeftHanded = prefs["input:left_handed"];

                        if (prefs["input:follow_mouse"] !== undefined)
                            mouseFollowMouse = prefs["input:follow_mouse"];

                        if (prefs["cursor:inactive_timeout"] !== undefined)
                            cursorInactiveTimeout = Math.round(prefs["cursor:inactive_timeout"]);

                        if (prefs["cursor:no_warps"] !== undefined)
                            cursorNoWarps = prefs["cursor:no_warps"];

                        if (prefs["input:touchpad:natural_scroll"] !== undefined)
                            touchpadNaturalScroll = prefs["input:touchpad:natural_scroll"];

                        if (prefs["input:touchpad:tap-to-click"] !== undefined)
                            touchpadTapToClick = prefs["input:touchpad:tap-to-click"];

                        if (prefs["input:touchpad:disable_while_typing"] !== undefined)
                            touchpadDisableWhileTyping = prefs["input:touchpad:disable_while_typing"];

                    } catch (e) {
                        console.error("Error parsing hypr prefs: " + e);
                    }
                }
            }
        }

    }

}
