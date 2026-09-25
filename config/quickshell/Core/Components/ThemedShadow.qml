import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Effects
import qs.Core
import qs.Core.Services

RectangularShadow {
    id: root

    property bool active: true

    visible: active && HyprlandService.hyprShadow
    blur: HyprlandService.hyprShadowRange
    spread: HyprlandService.hyprShadowRenderPower
    color: Theme.shadow
}
