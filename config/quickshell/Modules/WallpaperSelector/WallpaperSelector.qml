import QtQuick
import qs.Core
import qs.Core.Services
import qs.Core.Windows

OverlayWindow {
    id: root

    widgetId: "wallpaper"
    enableShadow: true
    positionAtBottom: true
    preferredWidth: content.implicitWidth + (contentPadding * 2)
    preferredHeight: content.implicitHeight + (contentPadding * 2)
    initialFocusItem: content.initialFocusItem
    onWidgetOpened: {
        content.resetWallpaperSelector();
    }

    WallpaperSelectorContent {
        id: content

        widget: root
    }

}
