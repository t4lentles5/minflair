import QtQuick
import Quickshell
import Quickshell.Io
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Core.Utils
import qs.Modules.Settings.Components

AppContainer {
    id: barSettingsRoot

    AppGroup {
        title: "Bar Style"
        icon: "bar"

        SettingSegmented {
            label: "Style"
            description: "Choose between Convex or Island"
            model: [{
                "text": "Convex",
                "value": "convex"
            }, {
                "text": "Island",
                "value": "island"
            }]
            currentValue: SettingsService.barStyle
            onActivated: (value) => {
                SettingsService.barStyle = value;
            }
        }

    }

    // ISLAND MODE WIDGETS
    AppGroup {
        title: "Island Bar Widgets"
        icon: "widgets"
        visible: SettingsService.barIslandMode

        SettingToggle {
            label: "Single Island"
            description: "Show only the center pill with the star, clock and music cava. Workspaces and tray are hidden."
            bindTarget: SettingsService
            bindProperty: "islandSinglePill"
        }

        SettingSegmented {
            label: "Right Circular Island"
            description: "Choose what to display in the right circular island (Music cover or Control Center)"
            visible: !SettingsService.islandSinglePill
            model: [{
                "text": "Auto (Music or Tune)",
                "value": "auto"
            }, {
                "text": "Always Music",
                "value": "music"
            }, {
                "text": "Always Control Center",
                "value": "control_center"
            }]
            currentValue: SettingsService.islandRightMode
            onActivated: (value) => {
                SettingsService.islandRightMode = value;
            }
        }

        SettingToggle {
            label: "Show Workspaces"
            description: "Display interactive workspace indicators in the left island"
            visible: !SettingsService.islandSinglePill
            bindTarget: SettingsService
            bindProperty: "islandShowWorkspaces"
        }

        SettingToggle {
            label: "Show System Tray"
            description: "Display system tray icons in the right island"
            visible: !SettingsService.islandSinglePill
            bindTarget: SettingsService
            bindProperty: "islandShowTray"
        }

    }

    AppGroup {
        title: "Clock Format"
        icon: "clock"

        SettingToggle {
            label: "24-Hour Time"
            description: "Use 24-hour time format instead of 12-hour AM/PM"
            bindTarget: SettingsService
            bindProperty: "clock24h"
        }

        SettingToggle {
            label: "Show Seconds"
            description: "Display seconds on the main clock"
            bindTarget: SettingsService
            bindProperty: "clockSeconds"
        }

        SettingToggle {
            label: "Show Date"
            description: "Display the current date next to the clock"
            bindTarget: SettingsService
            bindProperty: "clockShowDate"
        }

    }

    AppGroup {
        title: "Workspaces"
        icon: "slider"

        SettingSpinBox {
            label: "Number of Workspaces"
            description: "Set the total number of workspaces shown on the bar"
            value: SettingsService.numberOfWorkspaces
            from: 1
            to: 20
            stepSize: 1
            decimals: 0
            suffix: ""
            onMoved: (val) => {
                SettingsService.numberOfWorkspaces = val;
            }
        }

    }

}
