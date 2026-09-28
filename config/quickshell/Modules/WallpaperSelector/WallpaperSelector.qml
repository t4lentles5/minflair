import QtQuick
import qs.Core
import qs.Core.Services
import qs.Core.Windows

OverlayWindow {
    id: root

    popupId: "wallpaper"
    enableShadow: true
    positionAtBottom: true
    enableBottomNotch: false
    preferredWidth: content.implicitWidth + (contentPadding * 2)
    preferredHeight: content.implicitHeight + (contentPadding * 2)
    borderWidth: 0
    initialFocusItem: content.initialFocusItem
    onPopupOpened: {
        content.resetWallpaperSelector();
    }

    WallpaperSelectorContent {
        id: content

        widget: root
    }

}
