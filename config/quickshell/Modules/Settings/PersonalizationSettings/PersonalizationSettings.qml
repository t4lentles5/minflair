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
    property var availableFonts: []
    property string currentFontName: "Geist"
    property int currentFontSize: 11
    property var availableCursors: []

    function applyFont() {
        SettingsService.fontFamily = appearanceRoot.currentFontName;
        setFontProc.command = ["python3", Quickshell.shellDir + "/Scripts/apply_font.py", appearanceRoot.currentFontName, appearanceRoot.currentFontSize.toString()];
        setFontProc.running = false;
        setFontProc.running = true;
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
    }

    Connections {
        function onBgChanged() {
            appearanceRoot.showingDark = ColorUtils.isDark(Theme.bg);
        }

        target: Theme
    }

    Process {
        id: setFontProc
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
                    if (changed)
                        appearanceRoot.availableFonts = arr;

                }
            }
        }

    }

    Process {
        id: getFontProc

        command: ["sh", "-c", "gsettings get org.gnome.desktop.interface font-name | tr -d \"'\""]
        Component.onCompleted: running = true

        stdout: SplitParser {
            onRead: (data) => {
                if (data && data.trim() !== "") {
                    let full = data.trim();
                    let match = full.match(/(.*)\s+(\d+)$/);
                    if (match) {
                        appearanceRoot.currentFontName = match[1];
                        appearanceRoot.currentFontSize = parseInt(match[2]);
                    } else {
                        appearanceRoot.currentFontName = full;
                        appearanceRoot.currentFontSize = 11;
                    }
                    if (Math.round(11 * SettingsService.fontScale) !== appearanceRoot.currentFontSize)
                        SettingsService.fontScale = appearanceRoot.currentFontSize / 11;

                    if (appearanceRoot.availableFonts.indexOf(appearanceRoot.currentFontName) === -1) {
                        let arr = appearanceRoot.availableFonts.slice();
                        arr.unshift(appearanceRoot.currentFontName);
                        appearanceRoot.availableFonts = arr;
                    }
                }
            }
        }

    }

    Process {
        id: fetchCursorsProc

        command: ["sh", "-c", "find /usr/share/icons ~/.local/share/icons ~/.icons -type d -name 'cursors' 2>/dev/null | awk -F'/' '{print $(NF-1)}' | sort -u"]
        Component.onCompleted: running = true

        stdout: SplitParser {
            onRead: (data) => {
                if (data) {
                    let lines = data.split('\n').map((x) => {
                        return x.trim();
                    }).filter((x) => {
                        return x !== "";
                    });
                    let arr = appearanceRoot.availableCursors.slice();
                    let changed = false;
                    lines.forEach((l) => {
                        if (arr.indexOf(l) === -1) {
                            arr.push(l);
                            changed = true;
                        }
                    });
                    if (changed)
                        appearanceRoot.availableCursors = arr;

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

            label: "System Font"
            description: "Global font for GTK, Qt and Shell"
            comboWidth: 260
            searchable: true
            model: appearanceRoot.availableFonts
            Component.onCompleted: {
                for (let i = 0; i < appearanceRoot.availableFonts.length; i++) {
                    if (appearanceRoot.availableFonts[i] === appearanceRoot.currentFontName) {
                        fontSelect.currentIndex = i;
                        return ;
                    }
                }
                fontSelect.currentIndex = 0;
            }
            onActivated: (index) => {
                let newFont = model[index];
                if (appearanceRoot.currentFontName !== newFont) {
                    appearanceRoot.currentFontName = newFont;
                    appearanceRoot.applyFont();
                }
            }

            Connections {
                function onCurrentFontNameChanged() {
                    for (let i = 0; i < appearanceRoot.availableFonts.length; i++) {
                        if (appearanceRoot.availableFonts[i] === appearanceRoot.currentFontName) {
                            fontSelect.currentIndex = i;
                            return ;
                        }
                    }
                    fontSelect.currentIndex = 0;
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

    AppGroup {
        title: "Cursor"
        icon: "cursor"

        ThemedSelect {
            id: cursorSelect

            function updateSelection() {
                for (let i = 0; i < appearanceRoot.availableCursors.length; i++) {
                    if (appearanceRoot.availableCursors[i] === SettingsService.cursorTheme) {
                        cursorSelect.currentIndex = i;
                        return ;
                    }
                }
            }

            label: "Cursor Theme"
            description: "Global mouse cursor theme"
            comboWidth: 260
            searchable: true
            model: appearanceRoot.availableCursors
            Component.onCompleted: updateSelection()
            onModelChanged: updateSelection()
            onActivated: (index) => {
                let newTheme = model[index];
                if (SettingsService.cursorTheme !== newTheme)
                    SettingsService.cursorTheme = newTheme;

            }

            Connections {
                function onCursorThemeChanged() {
                    cursorSelect.updateSelection();
                }

                target: SettingsService
            }

        }

        SettingSegmented {
            label: "Cursor Size"
            description: "Size of the mouse cursor"
            model: [{
                "text": "24",
                "value": 24
            }, {
                "text": "32",
                "value": 32
            }, {
                "text": "48",
                "value": 48
            }, {
                "text": "64",
                "value": 64
            }]
            currentValue: SettingsService.cursorSize
            onActivated: (value) => {
                SettingsService.cursorSize = value;
            }
        }

    }

    AppGroup {
        title: "Wallpaper"
        icon: "picture"

        SettingToggle {
            id: autoShuffleToggle

            label: "Auto-shuffle Wallpapers"
            onCheckedChanged: {
                if (checked !== HyprlandService.wpAutoShuffle)
                    HyprlandService.wpAutoShuffle = checked;

            }

            Binding {
                target: autoShuffleToggle
                property: "checked"
                value: HyprlandService.wpAutoShuffle
            }

        }

        SettingSpinBox {
            enabled: HyprlandService.wpAutoShuffle
            opacity: enabled ? 1 : 0.5
            label: "Shuffle Interval"
            from: 1
            to: 60
            stepSize: 1
            value: HyprlandService.wpShuffleInterval
            suffix: " min"
            decimals: 0
            onMoved: (val) => {
                HyprlandService.wpShuffleInterval = Math.round(val);
            }
        }

        ThemedSelect {
            label: "Transition Type"
            model: ["none", "grow", "fade", "wipe", "wave", "random"]
            currentIndex: {
                if (!HyprlandService.wpEnableTransitions)
                    return 0;

                let idx = model.indexOf(HyprlandService.wpTransitionType);
                return idx !== -1 ? idx : 1;
            }
            onActivated: (index) => {
                let val = model[index];
                if (val === "none") {
                    HyprlandService.wpEnableTransitions = false;
                } else {
                    HyprlandService.wpEnableTransitions = true;
                    HyprlandService.wpTransitionType = val;
                }
            }
        }

        ThemedSelect {
            label: "Transition Position"
            model: ["top-left", "top", "top-right", "left", "center", "right", "bottom-left", "bottom", "bottom-right"]
            currentIndex: {
                let idx = model.indexOf(HyprlandService.wpTransitionPos);
                return idx !== -1 ? idx : 4;
            }
            onActivated: (index) => {
                HyprlandService.wpTransitionPos = model[index];
            }
            enabled: HyprlandService.wpEnableTransitions && HyprlandService.wpTransitionType !== "random"
            opacity: enabled ? 1 : 0.4

            Behavior on opacity {
                NumberAnimation {
                    duration: Constants.animFast
                }

            }

        }

        ColumnLayout {
            spacing: Constants.sizeLg
            Layout.fillWidth: true
            enabled: HyprlandService.wpEnableTransitions
            opacity: enabled ? 1 : 0.4

            SettingSegmented {
                label: "Transition Speed"
                model: [{
                    "text": "Slow",
                    "value": 60
                }, {
                    "text": "Normal",
                    "value": 120
                }, {
                    "text": "Fast",
                    "value": 180
                }, {
                    "text": "Ultra",
                    "value": 240
                }]
                currentValue: HyprlandService.wpTransitionStep
                onActivated: (val) => {
                    HyprlandService.wpTransitionStep = val;
                }
            }

            SettingSegmented {
                label: "Transition Frame Rate"
                model: [{
                    "text": "30",
                    "value": 30
                }, {
                    "text": "60",
                    "value": 60
                }, {
                    "text": "120",
                    "value": 120
                }, {
                    "text": "144",
                    "value": 144
                }]
                currentValue: HyprlandService.wpTransitionFps
                onActivated: (val) => {
                    HyprlandService.wpTransitionFps = val;
                }
            }

            ThemedSlider {
                label: "Transition Angle"
                from: 0
                to: 360
                stepSize: 10
                value: HyprlandService.wpTransitionAngle
                suffix: "°"
                decimals: 0
                visible: HyprlandService.wpTransitionType === "wipe" || HyprlandService.wpTransitionType === "wave"
                onMoved: (val) => {
                    HyprlandService.wpTransitionAngle = Math.round(val);
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: Constants.animFast
                }

            }

        }

    }

}
