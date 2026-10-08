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

        SettingSegmented {
            label: "Right Circular Island"
            description: "Choose what to display in the right circular island (Music cover or Control Center)"
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

    }

    AppGroup {
        title: "Clock Format"
        icon: "clock"

        SettingToggle {
            label: "24-Hour Time"
            description: "Use 24-hour time format instead of 12-hour AM/PM"
            checked: SettingsService.clock24h
            onCheckedChanged: {
                SettingsService.clock24h = checked;
            }
        }

        SettingToggle {
            label: "Show Seconds"
            description: "Display seconds on the main clock"
            checked: SettingsService.clockSeconds
            onCheckedChanged: {
                SettingsService.clockSeconds = checked;
            }
        }

        SettingToggle {
            label: "Show Date"
            description: "Display the current date next to the clock"
            checked: SettingsService.clockShowDate
            onCheckedChanged: {
                SettingsService.clockShowDate = checked;
            }
        }

    }

}
