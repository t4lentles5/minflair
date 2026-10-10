import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.Core
import qs.Core.Components
import qs.Core.Services

QuickSettingsTile {
    id: root

    isActive: DisplayProfileService.caffeineActive
    icon: !isActive ? "coffee" : "coffee-filled"
    label: "Caffeine"
    subtitle: isActive ? "Screen on" : "Off"
    onMenuClicked: clicked()
    onClicked: {
        DisplayProfileService.caffeineActive = !DisplayProfileService.caffeineActive;
    }
}
