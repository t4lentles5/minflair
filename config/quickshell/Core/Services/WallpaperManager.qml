import QtQuick
import Quickshell
import Quickshell.Io
import qs.Core
import qs.Core.Services
pragma Singleton

QtObject {
    id: root

    property string currentWallpaper: ""
    property string currentWallpaperPath: ""
    property string transitionType: HyprlandService.wpTransitionType
    property int transitionStep: HyprlandService.wpTransitionStep
    property string transitionPos: HyprlandService.wpTransitionPos
    property int transitionFps: HyprlandService.wpTransitionFps
    property int transitionAngle: HyprlandService.wpTransitionAngle
    property string resizeMode: HyprlandService.wpResizeMode
    property string cropGravity: HyprlandService.wpCropGravity
    property bool enableTransitions: HyprlandService.wpEnableTransitions
    property bool autoShuffle: HyprlandService.wpAutoShuffle
    property int shuffleInterval: HyprlandService.wpShuffleInterval
    property Process wallpaperApplyProc
    property Process wallpaperSaveProc
    property Process wallpaperLoader
    property Process randomWallpaperProc
    property Timer shuffleTimer

    function applyWallpaperWithSync(wallpaperName, rawPath) {
        currentWallpaper = wallpaperName;
        currentWallpaperPath = rawPath;
        saveCurrentWallpaper(wallpaperName);
        applyWallpaper(rawPath);
    }

    function reapplyCurrentWallpaper() {
        let p = currentWallpaperPath;
        if (p && !p.startsWith("/"))
            p = Quickshell.env("HOME") + "/Pictures/Wallpapers/" + p;
        else if (!p && currentWallpaper)
            p = currentWallpaper.startsWith("/") ? currentWallpaper : (Quickshell.env("HOME") + "/Pictures/Wallpapers/" + currentWallpaper);
        if (p)
            applyWallpaperInstant(p);

    }

    function applyWallpaperInstant(rawPath) {
        wallpaperApplyProc.running = false;
        let rMode = HyprlandService.wpResizeMode || "crop";
        let gravity = HyprlandService.wpCropGravity || "center";
        let cmd = ["awww", "img", rawPath, "--resize", rMode];
        if (rMode === "crop")
            cmd.push("--crop-gravity", gravity);

        cmd.push("--transition-type", "none");
        wallpaperApplyProc.command = cmd;
        wallpaperApplyProc.startDetached();
    }

    function applyWallpaper(rawPath) {
        wallpaperApplyProc.running = false;
        let rMode = HyprlandService.wpResizeMode || "crop";
        let gravity = HyprlandService.wpCropGravity || "center";
        let cmd = ["awww", "img", rawPath, "--resize", rMode];
        if (rMode === "crop")
            cmd.push("--crop-gravity", gravity);

        if (enableTransitions && SystemInfoService.powerProfile !== "power-saver") {
            cmd.push("--transition-type", transitionType, "--transition-pos", transitionPos, "--transition-step", String(transitionStep), "--transition-fps", String(transitionFps));
            if (transitionType === "wipe" || transitionType === "wave")
                cmd.push("--transition-angle", String(transitionAngle));

            wallpaperApplyProc.command = cmd;
        } else {
            cmd.push("--transition-type", "none");
            wallpaperApplyProc.command = cmd;
        }
        wallpaperApplyProc.startDetached();
    }

    function saveCurrentWallpaper(wallName) {
        wallpaperSaveProc.running = false;
        // The wallpaper name is passed as a positional argument and written with
        // printf, so quotes, newlines or shell metacharacters in a file name can
        // never break the command or inject code.
        // The SDDM cache is only written when the sddm component is enabled.
        wallpaperSaveProc.command = ["sh", "-c", "mkdir -p \"$HOME/.cache/quickshell\" && printf '%s' \"$1\" > \"$HOME/.cache/quickshell/current_wallpaper\" && if ! grep -qxF sddm \"$HOME/.config/minflair/preferences.conf\" 2>/dev/null; then mkdir -p /var/tmp/sddm-theme && printf '%s' \"$1\" > /var/tmp/sddm-theme/current_wallpaper; fi && python3 \"$2\" 2>/dev/null || true", "minflair-wallpaper", wallName, Quickshell.shellDir + "/Scripts/theme/apply_theme.py"];
        wallpaperSaveProc.startDetached();
    }

    function shuffle() {
        randomWallpaperProc.running = false;
        randomWallpaperProc.running = true;
    }

    Component.onCompleted: {
        wallpaperLoader.running = true;
    }

    shuffleTimer: Timer {
        interval: root.shuffleInterval * 60000
        running: root.autoShuffle
        repeat: true
        onTriggered: root.shuffle()
    }

    wallpaperApplyProc: Process {
    }

    wallpaperSaveProc: Process {
    }

    randomWallpaperProc: Process {
        command: ["bash", "-c", "find ~/Pictures/Wallpapers -maxdepth 2 -type f 2>/dev/null | grep -iE '\\.(jpg|jpeg|png|webp|gif)$' | shuf -n 1"]
        onExited: function(exitCode) {
            if (exitCode === 0) {
                let path = randomWallOutput.text.trim();
                if (path) {
                    let parts = path.split('/');
                    let wallName = parts[parts.length - 1];
                    root.applyWallpaperWithSync(wallName, path);
                }
            }
        }

        stdout: StdioCollector {
            id: randomWallOutput
        }

    }

    wallpaperLoader: Process {
        command: ["cat", Quickshell.env("HOME") + "/.cache/quickshell/current_wallpaper"]
        onExited: function(exitCode) {
            if (exitCode === 0) {
                let name = wallpaperLoaderOutput.text.trim();
                if (name) {
                    root.currentWallpaper = name;
                    root.currentWallpaperPath = name.startsWith("/") ? name : (Quickshell.env("HOME") + "/Pictures/Wallpapers/" + name);
                }
            }
        }

        stdout: StdioCollector {
            id: wallpaperLoaderOutput
        }

    }

}
