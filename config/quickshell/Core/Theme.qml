import QtQuick
import Quickshell
import Quickshell.Io
import qs.Core.Services
import qs.Core.Utils
pragma Singleton

QtObject {
    id: root

    property var themes: [{
        "name": "Default",
        "dark": {
            "name": "Default",
            "bg": '#030107',
            "fg": '#d1d1d1',
            "accent": '#a77ef5',
            "accentComplementary": '#f57eb6'
        },
        "light": {
            "name": "Default Light",
            "bg": '#e8dbff',
            "fg": '#1e1a2e',
            "accent": '#7040e8',
            "accentComplementary": '#e840a1'
        }
    }]
    property string currentScheme: "Default"
    property real bgOpacity: 1
    property color _rawBg: themes[0].dark.bg
    property color opaqueBg: _rawBg
    property color bg: Qt.rgba(_rawBg.r, _rawBg.g, _rawBg.b, bgOpacity)
    property bool isDark: ColorUtils.isDark(_rawBg)
    property color overlayBase: isDark ? Qt.rgba(fg.r * 0.3 + accent.r * 0.7, fg.g * 0.3 + accent.g * 0.7, fg.b * 0.3 + accent.b * 0.7, 1) : accent
    property color bgSecondary: Qt.rgba(overlayBase.r, overlayBase.g, overlayBase.b, isDark ? 0.05 : 0.1)
    property color bgTertiary: Qt.rgba(overlayBase.r, overlayBase.g, overlayBase.b, isDark ? 0.1 : 0.2)
    property color fg: themes[0].dark.fg
    property color muted: Qt.rgba(fg.r, fg.g, fg.b, 0.65)
    property color border: Qt.rgba(fg.r, fg.g, fg.b, 0.15)
    property color accent: themes[0].dark.accent
    property color accentComplementary: themes[0].dark.accentComplementary
    property color shadow: isDark ? Qt.rgba(0, 0, 0, 0.45) : Qt.rgba(0, 0, 0, 0.1)
    property bool generateFromWallpaper: false
    property bool wallpaperIsDark: true
    property var wallpaperColors: null
    property Process saver
    property Process loader
    property Process wallpaperLoader
    property Process generatorProc
    property Process applyThemeProc
    property Connections wpConn

    signal themeApplied()

    function applyScheme(scheme) {
        currentScheme = scheme.name;
        _rawBg = scheme.bg;
        fg = scheme.fg;
        accent = scheme.accent;
        accentComplementary = scheme.accentComplementary;
        saveScheme();
    }

    function applyWallpaperTheme(isDark) {
        if (!wallpaperColors || !wallpaperColors.dark || !wallpaperColors.light)
            return ;

        wallpaperIsDark = isDark;
        let activeScheme = isDark ? wallpaperColors.dark : wallpaperColors.light;
        applyScheme({
            "name": activeScheme.name || "Wallpaper Theme",
            "bg": activeScheme.bg,
            "fg": activeScheme.fg,
            "muted": activeScheme.muted,
            "border": activeScheme.border,
            "accent": activeScheme.accent,
            "accentComplementary": activeScheme.accentComplementary,
            "shadow": activeScheme.shadow || "#000000"
        });
    }

    function saveScheme() {
        let obj = {
            "name": currentScheme,
            "generateFromWallpaper": generateFromWallpaper,
            "wallpaperIsDark": wallpaperIsDark,
            "bgOpacity": bgOpacity,
            "bg": "" + _rawBg,
            "fg": "" + fg,
            "muted": "" + muted,
            "border": "" + border,
            "accent": "" + accent,
            "accentComplementary": "" + accentComplementary,
            "shadow": "" + shadow
        };
        let json = JSON.stringify(obj);
        let home = Quickshell.env("HOME");
        saver.running = false;
        saver.command = ["bash", "-c", "mkdir -p '" + home + "/.cache/quickshell' && echo '" + json + "' > '" + home + "/.cache/quickshell/colorscheme.json'"];
        saver.running = true;
    }

    function generateTheme(wallpaperPath) {
        generatorProc.running = false;
        generatorProc.command = ["python3", Quickshell.shellDir + "/Scripts/theme/generate_theme.py", wallpaperPath, generateFromWallpaper ? "True" : "False"];
        generatorProc.running = true;
    }

    function loadScheme() {
        loader.running = false;
        loader.running = true;
        wallpaperLoader.running = false;
        wallpaperLoader.running = true;
    }

    Component.onCompleted: loadScheme()

    wpConn: Connections {
        function onCurrentWallpaperPathChanged() {
            if (root.generateFromWallpaper && WallpaperManager.currentWallpaperPath !== "")
                root.generateTheme(WallpaperManager.currentWallpaperPath);

        }

        target: WallpaperManager
    }

    generatorProc: Process {
        id: generatorProc

        onExited: function(exitCode) {
            if (exitCode === 0) {
                let output = generatorOutput.text;
                let colorsLine = "";
                let lines = output.split("\n");
                for (let i = 0; i < lines.length; i++) {
                    if (lines[i].startsWith("COLORS:")) {
                        colorsLine = lines[i].substring(7);
                        break;
                    }
                }
                if (colorsLine) {
                    try {
                        let colors = JSON.parse(colorsLine);
                        root.wallpaperColors = colors;
                        if (colors.activeIsDark !== undefined)
                            root.wallpaperIsDark = colors.activeIsDark;

                        if (root.generateFromWallpaper)
                            root.applyWallpaperTheme(root.wallpaperIsDark);

                    } catch (e) {
                        root.loadScheme();
                    }
                } else {
                    root.loadScheme();
                }
            }
        }

        stderr: StdioCollector {
            id: generatorError
        }

        stdout: StdioCollector {
            id: generatorOutput
        }

    }

    saver: Process {
        onExited: function(exitCode) {
            if (exitCode === 0) {
                applyThemeProc.running = false;
                applyThemeProc.command = ["python3", Quickshell.shellDir + "/Scripts/theme/apply_theme.py"];
                applyThemeProc.running = true;
            }
        }
    }

    loader: Process {
        command: ["cat", Quickshell.env("HOME") + "/.cache/quickshell/colorscheme.json"]
        onExited: function(exitCode) {
            if (exitCode === 0) {
                try {
                    let colors = JSON.parse(loaderOutput.text);
                    if (colors.generateFromWallpaper !== undefined)
                        root.generateFromWallpaper = colors.generateFromWallpaper;

                    if (colors.wallpaperIsDark !== undefined)
                        root.wallpaperIsDark = colors.wallpaperIsDark;

                    if (colors.name)
                        root.currentScheme = colors.name;

                    if (colors.bgOpacity !== undefined)
                        root.bgOpacity = colors.bgOpacity;

                    if (colors.bg)
                        root._rawBg = colors.bg;

                    if (colors.fg)
                        root.fg = colors.fg;

                    if (colors.accent)
                        root.accent = colors.accent;

                    if (colors.accentComplementary)
                        root.accentComplementary = colors.accentComplementary;

                    applyThemeProc.running = false;
                    applyThemeProc.command = ["python3", Quickshell.shellDir + "/Scripts/theme/apply_theme.py"];
                    applyThemeProc.running = true;
                } catch (e) {
                    root.applyScheme(root.themes[0].dark);
                }
            } else {
                root.applyScheme(root.themes[0].dark);
            }
        }

        stdout: StdioCollector {
            id: loaderOutput
        }

    }

    wallpaperLoader: Process {
        command: ["bash", "-c", "echo '{ \"dark\": '`cat ~/.cache/quickshell/wallpaper_colorscheme_dark.json 2>/dev/null || echo \"null\"`', \"light\": '`cat ~/.cache/quickshell/wallpaper_colorscheme_light.json 2>/dev/null || echo \"null\"`' }'"]
        onExited: function(exitCode) {
            if (exitCode === 0) {
                try {
                    root.wallpaperColors = JSON.parse(wallpaperLoaderOutput.text);
                } catch (e) {
                }
            }
        }

        stdout: StdioCollector {
            id: wallpaperLoaderOutput
        }

    }

    applyThemeProc: Process {
        onExited: function(exitCode) {
            if (exitCode === 0)
                root.themeApplied();

        }
    }

}
