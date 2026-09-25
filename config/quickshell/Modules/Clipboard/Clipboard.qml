import QtQuick
import qs.Core
import qs.Core.Windows

OverlayWindow {
    id: root

    popupId: "clipboard"
    enableShadow: true
    preferredWidth: 720
    preferredHeight: 480
    borderWidth: 0
    initialFocusItem: content.initialFocusItem
    onPopupOpened: {
        content.resetClipboard();
    }

    ClipboardContent {
        id: content

        widget: root
    }

}
