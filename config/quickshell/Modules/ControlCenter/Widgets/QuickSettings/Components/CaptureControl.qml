import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services

SvgIconButton {
    id: root

    icon: RecorderService.running ? "capture-filled" : "capture"
    iconColor: RecorderService.running ? Theme.accent : Theme.muted
    iconSize: Constants.sizeXl
    onClicked: function(mouse) {
        if (RecorderService.running) {
            RecorderService.toggle([]);
        } else {
            AppState.togglePopup("controlCenter");
            AppState.togglePopup("screenshot");
        }
    }
}
