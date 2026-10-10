import QtQuick
import qs.Core.Services
pragma Singleton

QtObject {
    property string fontFamily: SettingsService.fontFamily
    property int size3Xs: 2
    property int size2Xs: 4
    property int sizeXs: 8
    property int sizeSm: 12
    property int sizeMd: 14
    property int sizeLg: 16
    property int sizeXl: 20
    property int size2Xl: 24
    property int size3Xl: 32
    property int size4Xl: 40
    property int size5Xl: 48
    readonly property real durationFactor: (HyprlandService.enableAnimations && !DisplayProfileService.gameModeActive && SystemInfoService.powerProfile !== "power-saver") ? (1 / Math.max(0.1, HyprlandService.animationSpeedFactor)) : 0
    property int animUltraFast: Math.round(100 * durationFactor)
    property int animFast: Math.round(150 * durationFactor)
    property int animNormal: Math.round(250 * durationFactor)
    property int animSlow: Math.round(350 * durationFactor)
    property int animUltraSlow: Math.round(400 * durationFactor)
    property int animExpressive: Math.round(500 * durationFactor)
}
