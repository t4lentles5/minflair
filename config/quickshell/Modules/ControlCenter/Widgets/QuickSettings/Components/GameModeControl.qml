import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services

QuickSettingsTile {
    id: root

    isActive: DisplayProfileService.gameModeActive
    icon: isActive ? "gamepad-filled" : "gamepad"
    label: "Game Mode"
    subtitle: isActive ? "Active" : "Off"
    onMenuClicked: clicked()
    onClicked: {
        DisplayProfileService.gameModeActive = !DisplayProfileService.gameModeActive;
    }
}
