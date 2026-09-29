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
            description: "Choose between Minflair, Island, Notch, or Convex"
            model: [{
                "text": "Minflair",
                "value": "minflair"
            }, {
                "text": "Island",
                "value": "island"
            }, {
                "text": "Notch",
                "value": "notch"
            }, {
                "text": "Convex",
                "value": "convex"
            }]
            currentValue: SettingsService.barStyle
            onActivated: (value) => {
                SettingsService.barStyle = value;
            }
        }

        SettingToggle {
            visible: SettingsService.barStyle === "convex"
            label: "Compact Bar"
            description: "Reduce bar height and simplify buttons with divider separators"
            checked: SettingsService.barCompactMode
            onCheckedChanged: {
                SettingsService.barCompactMode = checked;
            }
        }

    }

    AppGroup {
        title: "Bar Widgets"
        icon: "widgets"

        SettingSlotSelect {
            label: "Left Slot 1"
            description: "First widget on the left"
            slotId: "barSlotL1"
            updateFn: (val) => {
                return SettingsService.barSlotL1 = val;
            }
        }

        SettingSlotSelect {
            label: "Left Slot 2"
            description: "Second widget on the left"
            slotId: "barSlotL2"
            updateFn: (val) => {
                return SettingsService.barSlotL2 = val;
            }
        }

        SettingSlotSelect {
            label: "Left Slot 3"
            description: "Third widget on the left"
            slotId: "barSlotL3"
            updateFn: (val) => {
                return SettingsService.barSlotL3 = val;
            }
        }

        SettingSlotSelect {
            label: "Center Slot 1"
            description: "First widget in the center of the bar"
            slotId: "barSlotC1"
            updateFn: (val) => {
                return SettingsService.barSlotC1 = val;
            }
        }

        SettingSlotSelect {
            label: "Center Slot 2"
            description: "Second widget in the center of the bar"
            slotId: "barSlotC2"
            updateFn: (val) => {
                return SettingsService.barSlotC2 = val;
            }
        }

        SettingSlotSelect {
            label: "Right Slot 1"
            description: "First widget on the right"
            slotId: "barSlotR1"
            updateFn: (val) => {
                return SettingsService.barSlotR1 = val;
            }
        }

        SettingSlotSelect {
            label: "Right Slot 2"
            description: "Second widget on the right"
            slotId: "barSlotR2"
            updateFn: (val) => {
                return SettingsService.barSlotR2 = val;
            }
        }

        SettingSlotSelect {
            label: "Right Slot 3"
            description: "Third widget on the right"
            slotId: "barSlotR3"
            updateFn: (val) => {
                return SettingsService.barSlotR3 = val;
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
