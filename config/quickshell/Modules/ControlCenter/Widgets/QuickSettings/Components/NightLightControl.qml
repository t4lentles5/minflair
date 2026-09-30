import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.Core
import qs.Core.Components
import qs.Core.Services

QuickSettingsTile {
    id: root

    isActive: DisplayProfileService.nightLightActive
    icon: isActive ? "moon-filled" : "moon"
    label: "Night Light"
    subtitle: isActive ? "On" : "Off"
    onMenuClicked: clicked()
    onClicked: {
        DisplayProfileService.nightLightActive = !DisplayProfileService.nightLightActive;
    }
}
