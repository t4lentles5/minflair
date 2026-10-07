import QtQuick
import qs.Modules.Bar.Components

BaseNotifLayer {
    id: root

    property alias isHostPanel: root.isExpandedOpen

    lockScope: "island"
    isConvex: false
}
