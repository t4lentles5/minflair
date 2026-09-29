import QtQuick
import qs.Core
import qs.Core.Windows

OverlayWindow {
    id: root

    popupId: "screenshot"
    exclusive: true
    positionAtBottom: true
    contentPadding: 0
    windowRadius: Constants.sizeMd
    preferredWidth: content.implicitWidth
    preferredHeight: content.implicitHeight
    initialFocusItem: content.initialFocusItem
    enableShadow: true
    onPopupOpened: {
        content.resetScreenCapture();
    }

    ScreenCaptureContent {
        id: content

        widget: root
    }

}
