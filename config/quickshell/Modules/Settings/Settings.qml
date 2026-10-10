import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Core.Windows
import qs.Modules.Settings.BarSettings
import qs.Modules.Settings.Components
import qs.Modules.Settings.EffectsSettings
import qs.Modules.Settings.InputAndClipboardSettings
import qs.Modules.Settings.IntegrationsSettings
import qs.Modules.Settings.MouseSettings
import qs.Modules.Settings.PersonalizationSettings
import qs.Modules.Settings.SystemInfo
import qs.Modules.Settings.WallpaperSettings
import qs.Modules.Settings.WindowSettings

AppWindow {
    id: root

    property var pageComponents: [personalizationComp, barSettingsComp, effectsComp, windowComp, integrationsComp, mouseComp, inputAndClipboardComp, systemInfoComp, wallpaperComp]
    property int activeTab: 0
    readonly property var navOrder: [0, 8, 1, 2, 3, 5, 6, 4, 7]
    readonly property var tabMetadata: ({
        "0": {
            "title": "Appearance",
            "subtitle": "Themes, dynamic colors, and system typography",
            "category": "DESKTOP"
        },
        "1": {
            "title": "Desktop Bar",
            "subtitle": "Configure widgets, layout, style, and bar visibility",
            "category": "DESKTOP"
        },
        "2": {
            "title": "Visual Effects",
            "subtitle": "Blur, opacity, window animations, and shadow effects",
            "category": "DESKTOP"
        },
        "3": {
            "title": "Windows & Display",
            "subtitle": "Window rules, borders, gaps, and monitor arrangements",
            "category": "DESKTOP"
        },
        "4": {
            "title": "Integrations & Apps",
            "subtitle": "Weather service, GitHub status, notifications, and launcher",
            "category": "MANAGEMENT"
        },
        "5": {
            "title": "Mouse & Touchpad",
            "subtitle": "Cursor speed, acceleration, scrolling, and touchpad gestures",
            "category": "INPUT & HARDWARE"
        },
        "6": {
            "title": "Keyboard & Clipboard",
            "subtitle": "Keyboard layouts, repeat delay, and clipboard history",
            "category": "INPUT & HARDWARE"
        },
        "7": {
            "title": "About System",
            "subtitle": "Hardware specifications, kernel, and software environment",
            "category": "ABOUT"
        },
        "8": {
            "title": "Wallpaper",
            "subtitle": "Screen crop preview, scaling modes, transitions, and shuffle",
            "category": "DESKTOP"
        }
    })
    readonly property var currentTabMeta: tabMetadata[activeTab] || tabMetadata[0]

    widgetId: "minflair_settings"
    windowTitle: "Minflair Settings"
    contentPadding: 0
    onIsOpenChanged: {
        if (isOpen) {
            if (AppState.pendingSettingsTab !== -1) {
                activeTab = AppState.pendingSettingsTab;
                AppState.pendingSettingsTab = -1;
            } else {
                activeTab = 0;
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 0

        SettingsSidebar {
            id: sidebar

            Layout.fillHeight: true
            activeTab: root.activeTab
            onTabClicked: (id) => {
                root.activeTab = id;
            }
        }

        ColumnLayout {
            id: contentContainer

            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            AppHeader {
                title: root.currentTabMeta.title
                category: root.currentTabMeta.category
                subtitle: root.currentTabMeta.subtitle
                showDivider: true
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                PageTransitionView {
                    anchors.fill: parent
                    activeIndex: root.activeTab
                    order: root.navOrder
                    onContentNeedsUpdate: (index) => {
                        pageLoader.sourceComponent = root.pageComponents[index];
                    }

                    Loader {
                        id: pageLoader

                        anchors.fill: parent
                        sourceComponent: personalizationComp
                    }

                }

            }

        }

    }

    Shortcut {
        sequence: "Ctrl+Tab"
        enabled: root.isOpen && root.pageComponents && root.pageComponents.length > 1
        onActivated: {
            let currentIdx = root.navOrder.indexOf(root.activeTab);
            if (currentIdx === -1)
                currentIdx = 0;

            let nextIdx = (currentIdx + 1) % root.navOrder.length;
            root.activeTab = root.navOrder[nextIdx];
        }
    }

    Shortcut {
        sequence: "Ctrl+Shift+Tab"
        enabled: root.isOpen && root.pageComponents && root.pageComponents.length > 1
        onActivated: {
            let currentIdx = root.navOrder.indexOf(root.activeTab);
            if (currentIdx === -1)
                currentIdx = 0;

            let prevIdx = (currentIdx - 1 + root.navOrder.length) % root.navOrder.length;
            root.activeTab = root.navOrder[prevIdx];
        }
    }

    Component {
        id: personalizationComp

        PersonalizationSettings {
            anchors.fill: parent
        }

    }

    Component {
        id: barSettingsComp

        BarSettings {
            anchors.fill: parent
        }

    }

    Component {
        id: effectsComp

        EffectsSettings {
            anchors.fill: parent
        }

    }

    Component {
        id: windowComp

        WindowSettings {
            anchors.fill: parent
        }

    }

    Component {
        id: integrationsComp

        IntegrationsSettings {
            anchors.fill: parent
        }

    }

    Component {
        id: mouseComp

        MouseSettings {
            anchors.fill: parent
        }

    }

    Component {
        id: inputAndClipboardComp

        InputAndClipboardSettings {
            anchors.fill: parent
        }

    }

    Component {
        id: systemInfoComp

        SystemInfo {
            anchors.fill: parent
        }

    }

    Component {
        id: wallpaperComp

        WallpaperSettings {
            anchors.fill: parent
        }

    }

}
