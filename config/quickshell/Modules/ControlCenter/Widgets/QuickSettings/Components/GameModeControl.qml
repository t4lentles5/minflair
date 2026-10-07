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
    subtitle: DisplayProfileService.gameModeSubtitle
    onMenuClicked: clicked()
    onClicked: {
        DisplayProfileService.autoActivatedByDaemon = false;
        DisplayProfileService.gameModeActive = !DisplayProfileService.gameModeActive;
    }
}
