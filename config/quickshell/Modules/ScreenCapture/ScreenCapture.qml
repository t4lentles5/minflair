import QtQuick
import qs.Core
import qs.Core.Windows

OverlayWindow {
    id: root

    popupId: "screenshot"
    exclusive: true
    positionAtBottom: true
    contentPadding: 0
    borderWidth: 0
    windowRadius: Constants.sizeMd
    preferredWidth: content.implicitWidth > 0 ? content.implicitWidth : 448
    preferredHeight: 48
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
