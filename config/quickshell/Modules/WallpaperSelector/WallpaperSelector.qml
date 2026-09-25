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
    preferredWidth: 1040
    preferredHeight: (SettingsService.barFramedMode || SettingsService.barConvexMode) ? 240 : 248
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
