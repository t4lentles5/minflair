import QtQuick
import qs.Core
import qs.Core.Windows

OverlayWindow {
    id: root

    popupId: "launcher"
    enableShadow: true
    preferredWidth: 720
    preferredHeight: 480
    borderWidth: 0
    initialFocusItem: content.initialFocusItem
    onPopupOpened: {
        content.resetLauncher();
    }

    LauncherContent {
        id: content

        widget: root
    }

}
