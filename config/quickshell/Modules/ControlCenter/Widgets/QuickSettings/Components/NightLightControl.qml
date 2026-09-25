import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.Core
import qs.Core.Components
import qs.Core.Services

SvgIconButton {
    id: root

    icon: DisplayProfileService.nightLightActive ? "moon-filled" : "moon"
    iconColor: DisplayProfileService.nightLightActive ? Theme.accent : Theme.muted
    iconSize: Constants.sizeXl
    onClicked: {
        DisplayProfileService.nightLightActive = !DisplayProfileService.nightLightActive;
    }
}
