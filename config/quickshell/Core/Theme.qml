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
    property color bgSecondary: Qt.rgba(overlayBase.r, overlayBase.g, overlayBase.b, isDark ? 0.06 : 0.1)
    property color bgTertiary: Qt.rgba(overlayBase.r, overlayBase.g, overlayBase.b, isDark ? 0.02 : 0.04)
    property color bgAccent: Qt.rgba(accent.r, accent.g, accent.b, isDark ? 0.15 : 0.3)
    property color bgAccentComplementary: Qt.rgba(accentComplementary.r, accentComplementary.g, accentComplementary.b, isDark ? 0.15 : 0.3)
    property color fg: themes[0].dark.fg
    property color muted: Qt.rgba(fg.r, fg.g, fg.b, 0.4)
    property color border: isDark ? Qt.rgba(fg.r, fg.g, fg.b, 0.1) : Qt.rgba(fg.r, fg.g, fg.b, 0.2)
    property color accent: themes[0].dark.accent
    property color accentComplementary: themes[0].dark.accentComplementary
    property color shadow: isDark ? Qt.rgba(0, 0, 0, 0.75) : Qt.rgba(0, 0, 0, 0.45)
    readonly property color white: "#ffffff"
    readonly property color black: "#000000"
    property bool generateFromWallpaper: false
    property bool wallpaperIsDark: true
    property var wallpaperColors: null
    property var wallpaperDarkScheme: null
    property var wallpaperLightScheme: null
    property bool wallpaperDarkLoaded: false
    property bool wallpaperLightLoaded: false
    property var wallpaperVariants: []
    property int wallpaperVariant: 0
    property Process saver
    property Process loader
    property Process wallpaperDarkLoader
    property Process wallpaperLightLoader
    property Process wallpaperVariantsLoader
    property Process variantSelectProc
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

    function selectWallpaperVariant(index) {
        if (!generateFromWallpaper)
            return ;
        if (index < 0 || index >= wallpaperVariants.length)
            return ;
        if (index === wallpaperVariant)
            return ;

        let variant = wallpaperVariants[index];
        if (!variant || !variant.dark || !variant.light)
            return ;

        wallpaperVariant = index;
        wallpaperColors = {
            "dark": variant.dark,
            "light": variant.light
        };
        applyWallpaperTheme(wallpaperIsDark);

        // Keep the cached dark/light pair in sync so the choice survives a
        // restart. The active colorscheme.json is written by saveScheme above.
        variantSelectProc.running = false;
        variantSelectProc.command = ["python3", Quickshell.shellDir + "/Scripts/theme/generate_theme.py", "--select", String(index)];
        variantSelectProc.running = true;
    }

    function saveScheme() {
        let obj = {
            "name": currentScheme,
            "generateFromWallpaper": generateFromWallpaper,
            "wallpaperIsDark": wallpaperIsDark,
            "bgOpacity": bgOpacity,
            "bg": "" + _rawBg,
            "opaqueBg": "" + opaqueBg,
            "fg": "" + fg,
            "muted": "" + muted,
            "border": "" + border,
            "accent": "" + accent,
            "accentComplementary": "" + accentComplementary,
            "overlayBase": "" + overlayBase,
            "bgSecondary": "" + bgSecondary,
            "bgTertiary": "" + bgTertiary,
            "bgAccent": "" + bgAccent,
            "bgAccentComplementary": "" + bgAccentComplementary,
            "shadow": "" + shadow
        };
        let json = JSON.stringify(obj);
        // The JSON payload travels inside a quoted heredoc and $HOME is expanded by
        // the shell itself, so no value is ever interpolated into shell code. A
        // scheme name or path containing quotes can no longer break or inject.
        saver.running = false;
        saver.command = ["sh", "-c", "mkdir -p \"$HOME/.cache/quickshell\" && cat << 'EOF' > \"$HOME/.cache/quickshell/colorscheme.json.tmp\"\n" + json + "\nEOF\nmv -f \"$HOME/.cache/quickshell/colorscheme.json.tmp\" \"$HOME/.cache/quickshell/colorscheme.json\""];
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
        // Both cached wallpaper schemes are read directly, without a shell, and
        // published together so a partially loaded palette is never exposed.
        wallpaperDarkLoaded = false;
        wallpaperLightLoaded = false;
        wallpaperDarkLoader.running = false;
        wallpaperDarkLoader.running = true;
        wallpaperLightLoader.running = false;
        wallpaperLightLoader.running = true;
        // The list only feeds the picker; the cached pair above still owns the
        // colours that are applied, so an old cache without variants is fine.
        wallpaperVariantsLoader.running = false;
        wallpaperVariantsLoader.running = true;
    }

    function parseSchemeText(text, exitCode) {
        if (exitCode !== 0)
            return null;

        try {
            return JSON.parse(text);
        } catch (e) {
            return null;
        }
    }

    function publishWallpaperScheme(side, scheme) {
        if (side === "dark") {
            wallpaperDarkScheme = scheme;
            wallpaperDarkLoaded = true;
        } else {
            wallpaperLightScheme = scheme;
            wallpaperLightLoaded = true;
        }
        if (wallpaperDarkLoaded && wallpaperLightLoaded)
            wallpaperColors = {
            "dark": wallpaperDarkScheme,
            "light": wallpaperLightScheme
        };

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
                        root.wallpaperVariants = colors.variants || [];
                        root.wallpaperVariant = colors.selected !== undefined ? colors.selected : 0;
                        if (root.wallpaperVariant < 0 || root.wallpaperVariant >= root.wallpaperVariants.length)
                            root.wallpaperVariant = 0;

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

    wallpaperDarkLoader: Process {
        command: ["cat", Quickshell.env("HOME") + "/.cache/quickshell/wallpaper_colorscheme_dark.json"]
        onExited: function(exitCode) {
            root.publishWallpaperScheme("dark", root.parseSchemeText(wallpaperDarkOutput.text, exitCode));
        }

        stdout: StdioCollector {
            id: wallpaperDarkOutput
        }

    }

    wallpaperLightLoader: Process {
        command: ["cat", Quickshell.env("HOME") + "/.cache/quickshell/wallpaper_colorscheme_light.json"]
        onExited: function(exitCode) {
            root.publishWallpaperScheme("light", root.parseSchemeText(wallpaperLightOutput.text, exitCode));
        }

        stdout: StdioCollector {
            id: wallpaperLightOutput
        }

    }

    wallpaperVariantsLoader: Process {
        command: ["cat", Quickshell.env("HOME") + "/.cache/quickshell/wallpaper_variants.json"]
        onExited: function(exitCode) {
            if (exitCode !== 0) {
                root.wallpaperVariants = [];
                root.wallpaperVariant = 0;
                return ;
            }
            try {
                let data = JSON.parse(variantsOutput.text);
                let variants = data.variants || [];
                root.wallpaperVariants = variants;
                let selected = data.selected !== undefined ? data.selected : 0;
                root.wallpaperVariant = (selected >= 0 && selected < variants.length) ? selected : 0;
            } catch (e) {
                root.wallpaperVariants = [];
                root.wallpaperVariant = 0;
            }
        }

        stdout: StdioCollector {
            id: variantsOutput
        }

    }

    variantSelectProc: Process {
    }

    applyThemeProc: Process {
        onExited: function(exitCode) {
            if (exitCode === 0)
                root.themeApplied();

        }
    }

}
