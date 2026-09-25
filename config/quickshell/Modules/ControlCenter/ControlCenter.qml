import QtQuick
import qs.Core
import qs.Core.Windows

SidebarWindow {
    id: root

    property var notificationService: null

    popupId: "controlCenter"
    preferredHeight: root.isConvex ? Math.min(880, root._screenHeight > 0 ? root._screenHeight - 120 : 880) : (root._screenHeight > 0 ? root._screenHeight - 64 - 8 : 1000)
    backgroundColor: Theme.bg
    preferredWidth: content.implicitWidth + (Constants.sizeLg * 2)

    ControlCenterContent {
        id: content

        widget: root
        notificationService: root.notificationService
        isHorizontal: false
    }

}
