import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services

SvgIconButton {
    id: root

    icon: DisplayProfileService.gameModeActive ? "gamepad-filled" : "gamepad"
    iconColor: DisplayProfileService.gameModeActive ? Theme.accent : Theme.muted
    iconSize: Constants.sizeXl
    onClicked: {
        DisplayProfileService.gameModeActive = !DisplayProfileService.gameModeActive;
    }
}
