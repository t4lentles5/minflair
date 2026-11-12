import QtQuick
import qs.Core.Services
pragma Singleton

QtObject {
    // Single source of truth for the version shown in the UI (sidebar footer,
    // Settings → System Info). Keep it in sync with the release changelog.
    readonly property string appVersion: "2.3.0"
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
    // Gaming bar surface height. The surface, its exclusive zone and the overlay
    // must always use the same value, so it lives here as a single source of truth.
    property int gamingBarHeight: size3Xl + 2
    // Island idle pill height. The pills, the exclusive zone (bar surface) and
    // the overlay's starting height must share this value or gaps appear.
    property int islandBarHeight: size3Xl + size2Xs
    readonly property real durationFactor: (HyprlandService.enableAnimations && !DisplayProfileService.gameModeActive && SystemInfoService.powerProfile !== "power-saver") ? (1 / Math.max(0.1, HyprlandService.animationSpeedFactor)) : 0
    property int animUltraFast: Math.round(100 * durationFactor)
    property int animFast: Math.round(150 * durationFactor)
    property int animNormal: Math.round(250 * durationFactor)
    property int animSlow: Math.round(350 * durationFactor)
    property int animUltraSlow: Math.round(400 * durationFactor)
    property int animExpressive: Math.round(500 * durationFactor)
}
