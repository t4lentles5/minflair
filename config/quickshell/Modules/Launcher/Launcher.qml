import QtQuick
import qs.Core
import qs.Core.Windows

OverlayWindow {
    id: root

    popupId: "launcher"
    enableShadow: true
    preferredWidth: content.implicitWidth + (contentPadding * 2)
    preferredHeight: content.implicitHeight + (contentPadding * 2)
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
