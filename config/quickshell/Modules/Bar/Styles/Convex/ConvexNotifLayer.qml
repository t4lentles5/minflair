import QtQuick
import qs.Modules.Bar.Components

BaseNotifLayer {
    id: root

    required property int flareW

    flareW: root.flareW
    lockScope: "convex"
    isConvex: true
}
