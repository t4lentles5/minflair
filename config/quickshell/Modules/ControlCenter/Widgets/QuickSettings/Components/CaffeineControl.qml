import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.Core
import qs.Core.Components
import qs.Core.Services

SvgIconButton {
    id: root

    icon: !DisplayProfileService.caffeineActive ? "coffee" : "coffee-filled"
    iconColor: !DisplayProfileService.caffeineActive ? Theme.muted : Theme.accent
    iconSize: Constants.sizeXl
    onClicked: {
        DisplayProfileService.caffeineActive = !DisplayProfileService.caffeineActive;
    }
}
