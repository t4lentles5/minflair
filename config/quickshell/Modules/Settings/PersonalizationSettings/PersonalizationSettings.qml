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
    property string currentFontName: SettingsService.fontFamily || "Geist"
    property int currentFontSize: Math.round(11 * SettingsService.fontScale) || 11

    function applyFont() {
        SettingsService.fontFamily = appearanceRoot.currentFontName;
        SettingsService.applyFont(appearanceRoot.currentFontName, appearanceRoot.currentFontSize);
    }

    onShowingDarkChanged: {
        darkModeToggle.checked = showingDark;
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
        darkModeToggle.checked = showingDark;
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

    AppGroup {
        title: "Color Theme"
        icon: "color-palette"

        SettingToggle {
            label: "Dynamic Colors"
            description: "Generate color scheme from current wallpaper"
            checked: Theme.generateFromWallpaper
            onCheckedChanged: {
                if (checked !== Theme.generateFromWallpaper) {
                    Theme.generateFromWallpaper = checked;
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
            id: darkModeToggle

            label: "Dark Mode"
            description: "Use dark variant of the selected theme"
            onCheckedChanged: {
                if (appearanceRoot.showingDark !== checked)
                    appearanceRoot.showingDark = checked;

            }
        }

    }

    AppGroup {
        title: "System Fonts"
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

        SettingSpinBox {
            label: "Global Font Scale"
            description: "Scales fonts across Quickshell, GTK and Qt"
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
