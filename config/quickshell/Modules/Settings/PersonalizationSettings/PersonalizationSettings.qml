import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Core.Utils
import qs.Modules.Settings.Components

AppContainer {
    id: appearanceRoot

    property bool showingDark: true
    property var availableFonts: ["Geist"]
    property var availableMonoFonts: []
    property string currentFontName: SettingsService.fontFamily || "Geist"
    property int currentFontSize: Math.round(11 * SettingsService.fontScale) || 11

    function applyFont() {
        SettingsService.fontFamily = appearanceRoot.currentFontName;
        SettingsService.applyFont(appearanceRoot.currentFontName, appearanceRoot.currentFontSize);
    }

    // The terminal font only reaches Kitty when the components that carry it
    // are enabled, so the reason is shown when it will not be applied.
    function kittyFontDescription() {
        if (!ComponentService.isEnabled("font-sync"))
            return "Not applied: the font synchronization component is disabled";

        if (!ComponentService.isEnabled("kitty"))
            return "Not applied: the kitty component is disabled";

        return "Font used by the terminal";
    }

    onShowingDarkChanged: {
        if (!Theme.generateFromWallpaper) {
            let t = Theme.themes[0];
            let scheme = showingDark ? t.dark : t.light;
            Theme.applyScheme(scheme);
        } else {
            Theme.applyWallpaperTheme(showingDark);
        }
    }
    Component.onCompleted: {
        showingDark = ColorUtils.isDark(Theme.bg);
        if (appearanceRoot.availableFonts.indexOf(appearanceRoot.currentFontName) === -1) {
            let arr = appearanceRoot.availableFonts.slice();
            arr.unshift(appearanceRoot.currentFontName);
            appearanceRoot.availableFonts = arr;
        }
    }

    Connections {
        function onBgChanged() {
            appearanceRoot.showingDark = ColorUtils.isDark(Theme.bg);
        }

        target: Theme
    }

    Connections {
        function onFontFamilyChanged() {
            if (appearanceRoot.currentFontName !== SettingsService.fontFamily)
                appearanceRoot.currentFontName = SettingsService.fontFamily || "Geist";

        }

        function onFontScaleChanged() {
            appearanceRoot.currentFontSize = Math.round(11 * SettingsService.fontScale) || 11;
        }

        target: SettingsService
    }

    Process {
        id: fetchFontsProc

        command: ["sh", "-c", "fc-list : family | cut -d, -f1 | sort -u"]
        Component.onCompleted: running = true

        stdout: SplitParser {
            onRead: (data) => {
                if (data) {
                    let lines = data.split('\n').map((x) => {
                        return x.trim();
                    }).filter((x) => {
                        return x !== "";
                    });
                    let arr = appearanceRoot.availableFonts.slice();
                    let changed = false;
                    lines.forEach((l) => {
                        if (arr.indexOf(l) === -1) {
                            arr.push(l);
                            changed = true;
                        }
                    });
                    if (arr.indexOf(appearanceRoot.currentFontName) === -1) {
                        arr.unshift(appearanceRoot.currentFontName);
                        changed = true;
                    }
                    if (changed)
                        appearanceRoot.availableFonts = arr;

                }
            }
        }

    }

    Process {
        id: fetchMonoFontsProc

        // A terminal needs a monospace font, so only those are offered.
        command: ["sh", "-c", "fc-list :spacing=100 family | cut -d, -f1 | sort -u"]
        Component.onCompleted: running = true

        stdout: SplitParser {
            onRead: (data) => {
                if (!data)
                    return ;

                let lines = data.split('\n').map((x) => {
                    return x.trim();
                }).filter((x) => {
                    return x !== "";
                });
                let arr = appearanceRoot.availableMonoFonts.slice();
                let changed = false;
                lines.forEach((l) => {
                    if (arr.indexOf(l) === -1) {
                        arr.push(l);
                        changed = true;
                    }
                });
                // The font in use is always offered, even when fontconfig
                // does not know it.
                let current = SettingsService.kittyFontFamily;
                if (current && arr.indexOf(current) === -1) {
                    arr.unshift(current);
                    changed = true;
                }
                if (changed)
                    appearanceRoot.availableMonoFonts = arr;

            }
        }

    }

    AppGroup {
        title: "Color Theme"
        icon: "color-palette"

        SettingToggle {
            label: "Dynamic Colors"
            description: "Generate color scheme from current wallpaper"
            bindTarget: Theme
            bindProperty: "generateFromWallpaper"
            onCheckedChanged: {
                // The toggle writes generateFromWallpaper itself, so only the
                // side effect of regenerating the scheme is left to do.
                if (checked === Theme.generateFromWallpaper) {
                    if (checked) {
                        if (WallpaperManager.currentWallpaperPath !== "")
                            Theme.generateTheme(WallpaperManager.currentWallpaperPath);

                    } else {
                        let t = Theme.themes[0];
                        let baseName = Theme.currentScheme.replace(" Light", "");
                        for (let i = 0; i < Theme.themes.length; i++) {
                            if (Theme.themes[i].name === baseName) {
                                t = Theme.themes[i];
                                break;
                            }
                        }
                        let scheme = appearanceRoot.showingDark ? t.dark : t.light;
                        Theme.applyScheme(scheme);
                    }
                }
            }
        }

        ThemedSelect {
            label: "Static Theme"
            description: "Color scheme when dynamic colors are off"
            enabled: !Theme.generateFromWallpaper
            opacity: enabled ? 1 : 0.5
            model: {
                let m = [];
                for (let i = 0; i < Theme.themes.length; i++) {
                    m.push(Theme.themes[i].name);
                }
                return m;
            }
            currentIndex: {
                let baseName = Theme.currentScheme.replace(" Light", "");
                let idx = -1;
                for (let i = 0; i < Theme.themes.length; i++) {
                    if (Theme.themes[i].name === baseName) {
                        idx = i;
                        break;
                    }
                }
                return idx !== -1 ? idx : 0;
            }
            onActivated: (index) => {
                let t = Theme.themes[index];
                let scheme = appearanceRoot.showingDark ? t.dark : t.light;
                Theme.applyScheme(scheme);
            }
        }

        SettingToggle {
            label: "Dark Mode"
            description: "Use dark variant of the selected theme"
            bindTarget: appearanceRoot
            bindProperty: "showingDark"
        }

    }

    AppGroup {
        title: "Fonts"
        icon: "font"

        ThemedSelect {
            id: fontSelect

            function updateSelection() {
                for (let i = 0; i < appearanceRoot.availableFonts.length; i++) {
                    if (appearanceRoot.availableFonts[i] === appearanceRoot.currentFontName) {
                        fontSelect.currentIndex = i;
                        return ;
                    }
                }
                fontSelect.currentIndex = 0;
            }

            label: "System Font"
            description: "Global font for GTK, Qt and Shell"
            comboWidth: 260
            searchable: true
            model: appearanceRoot.availableFonts
            Component.onCompleted: updateSelection()
            onModelChanged: updateSelection()
            onActivated: (index) => {
                let newFont = model[index];
                if (appearanceRoot.currentFontName !== newFont) {
                    appearanceRoot.currentFontName = newFont;
                    appearanceRoot.applyFont();
                }
            }

            Connections {
                function onCurrentFontNameChanged() {
                    fontSelect.updateSelection();
                }

                target: appearanceRoot
            }

        }

        ThemedSelect {
            id: kittyFontSelect

            function updateSelection() {
                for (let i = 0; i < appearanceRoot.availableMonoFonts.length; i++) {
                    if (appearanceRoot.availableMonoFonts[i] === SettingsService.kittyFontFamily) {
                        kittyFontSelect.currentIndex = i;
                        return ;
                    }
                }
                kittyFontSelect.currentIndex = 0;
            }

            label: "Terminal Font"
            description: appearanceRoot.kittyFontDescription()
            comboWidth: 260
            searchable: true
            model: appearanceRoot.availableMonoFonts
            Component.onCompleted: updateSelection()
            onModelChanged: updateSelection()
            onActivated: (index) => {
                let newFont = model[index];
                if (SettingsService.kittyFontFamily !== newFont) {
                    SettingsService.kittyFontFamily = newFont;
                    SettingsService.applyKittyFont(newFont);
                }
            }

            Connections {
                function onKittyFontFamilyChanged() {
                    kittyFontSelect.updateSelection();
                }

                target: SettingsService
            }

        }

        SettingSpinBox {
            label: "Global Font Scale"
            description: "Scales fonts across Quickshell, GTK, Qt and the terminals"
            from: 0.7
            to: 2.5
            stepSize: 0.05
            value: SettingsService.fontScale
            suffix: "x"
            decimals: 2
            onMoved: (val) => {
                let newSize = Math.round(11 * val);
                if (appearanceRoot.currentFontSize !== newSize) {
                    appearanceRoot.currentFontSize = newSize;
                    SettingsService.fontScale = val;
                    appearanceRoot.applyFont();
                } else {
                    SettingsService.fontScale = val;
                }
            }
        }

    }

}
