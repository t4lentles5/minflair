import QtQuick
import qs.Core
import qs.Core.Windows

OverlayWindow {
    id: root

    popupId: "clipboard"
    enableShadow: true
    preferredWidth: content.implicitWidth + (contentPadding * 2)
    preferredHeight: content.implicitHeight + (contentPadding * 2)
    initialFocusItem: content.initialFocusItem
    onPopupOpened: {
        content.resetClipboard();
    }

    ClipboardContent {
        id: content

        widget: root
    }

}
