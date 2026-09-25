import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Core.Windows
import qs.Modules.Settings.BarSettings
import qs.Modules.Settings.EffectsSettings
import qs.Modules.Settings.InputAndClipboardSettings
import qs.Modules.Settings.IntegrationsSettings
import qs.Modules.Settings.PersonalizationSettings
import qs.Modules.Settings.SystemInfo
import qs.Modules.Settings.WindowSettings

SidebarAppWindow {
    id: root

    property var pageComponents: [personalizationComp, barSettingsComp, effectsComp, windowComp, integrationsComp, inputAndClipboardComp, systemInfoComp]

    popupId: "minflair_settings"
    windowTitle: "Minflair Settings"
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
    sidebarModel: [{
        "index": 0,
        "label": "Personalization",
        "icon": "color-palette"
    }, {
        "index": 1,
        "label": "Desktop Bar",
        "icon": "bar"
    }, {
        "index": 2,
        "label": "Desktop Effects",
        "icon": "sparkles"
    }, {
        "index": 3,
        "label": "Windows & Display",
        "icon": "monitor"
    }, {
        "index": 4,
        "label": "Integrations & Apps",
        "icon": "apps"
    }, {
        "index": 5,
        "label": "Input & Clipboard",
        "icon": "edit"
    }, {
        "index": 6,
        "label": "System & Updates",
        "icon": "info"
    }]
    onTabClicked: (id) => {
        root.activeTab = id;
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

    PageTransitionView {
        anchors.fill: parent
        activeIndex: root.activeTab
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
