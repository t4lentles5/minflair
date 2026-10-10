import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Shapes
import qs.Core
import qs.Core.Services

Item {
    id: root

    property int iconSize: Constants.size3Xl
    property color iconColor: Theme.accent
    property string plusStarPath: "M 11.6 2.5 Q 12 1.2 12.4 2.5 L 14 10 L 21.5 11.6 Q 22.8 12 21.5 12.4 L 14 14 L 12.4 21.5 Q 12 22.8 11.6 21.5 L 10 14 L 2.5 12.4 Q 1.2 12 2.5 11.6 L 10 10 Z"
    readonly property int scaledIconSize: Math.round(iconSize * SettingsService.fontScale)
    property bool enableIntroAnim: true
    property bool enableIntervalAnim: true

    width: scaledIconSize
    height: scaledIconSize
    implicitWidth: scaledIconSize
    implicitHeight: scaledIconSize
    layer.enabled: HyprlandService.hyprShadow && !DisplayProfileService.gameModeActive && (SystemInfoService.powerProfile !== "power-saver")

    Item {
        id: starContainer

        width: Constants.size2Xl
        height: Constants.size2Xl
        scale: root.scaledIconSize / Constants.size2Xl
        rotation: 45
        anchors.centerIn: parent
        enabled: false

        Item {
            id: mainStarShape

            width: Constants.size2Xl
            height: Constants.size2Xl
            transformOrigin: Item.Center
            rotation: 0

            Shape {
                width: Constants.size2Xl
                height: Constants.size2Xl
                preferredRendererType: Shape.CurveRenderer
                opacity: 0.4

                ShapePath {
                    fillColor: root.iconColor
                    strokeColor: "transparent"
                    strokeWidth: 0

                    PathSvg {
                        path: root.plusStarPath
                    }

                }

            }

        }

        Item {
            id: xStarShape

            width: Constants.size2Xl
            height: Constants.size2Xl
            transformOrigin: Item.Center
            rotation: 45
            scale: 1

            Shape {
                width: Constants.size2Xl
                height: Constants.size2Xl
                preferredRendererType: Shape.CurveRenderer
                opacity: 1

                ShapePath {
                    fillColor: root.iconColor
                    strokeColor: "transparent"
                    strokeWidth: 0

                    PathSvg {
                        path: root.plusStarPath
                    }

                }

            }

        }

        SequentialAnimation {
            id: introAnim

            running: HyprlandService.enableAnimations && root.enableIntroAnim

            PropertyAction {
                target: mainStarShape
                property: "scale"
                value: 0
            }

            PropertyAction {
                target: xStarShape
                property: "scale"
                value: 0
            }

            PropertyAction {
                target: mainStarShape
                property: "rotation"
                value: -360
            }

            PropertyAction {
                target: xStarShape
                property: "rotation"
                value: -315
            }

            PauseAnimation {
                duration: Math.max(0, Constants.animNormal - 50)
            }

            ParallelAnimation {
                ParallelAnimation {
                    NumberAnimation {
                        target: mainStarShape
                        property: "scale"
                        to: 1
                        duration: Constants.animExpressive + 400
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.2
                    }

                    NumberAnimation {
                        target: mainStarShape
                        property: "rotation"
                        to: 0
                        duration: Constants.animExpressive + 400
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.2
                    }

                }

                SequentialAnimation {
                    PauseAnimation {
                        duration: Constants.animFast
                    }

                    ParallelAnimation {
                        NumberAnimation {
                            target: xStarShape
                            property: "scale"
                            to: 1
                            duration: Constants.animExpressive + 400
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.2
                        }

                        NumberAnimation {
                            target: xStarShape
                            property: "rotation"
                            to: 45
                            duration: Constants.animExpressive + 400
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.2
                        }

                    }

                }

            }

        }

        SequentialAnimation {
            id: intervalAnim

            running: HyprlandService.enableAnimations && root.enableIntervalAnim && !introAnim.running
            loops: Animation.Infinite

            PauseAnimation {
                duration: Constants.animExpressive * 10
            }

            ParallelAnimation {
                NumberAnimation {
                    target: mainStarShape
                    property: "rotation"
                    from: 0
                    to: 90
                    duration: Constants.animUltraSlow * 3
                    easing.type: Easing.InOutBack
                    easing.overshoot: 1.2
                }

                NumberAnimation {
                    target: xStarShape
                    property: "rotation"
                    from: 45
                    to: -45
                    duration: Constants.animUltraSlow * 3
                    easing.type: Easing.InOutBack
                    easing.overshoot: 1.2
                }

            }

            PropertyAction {
                target: mainStarShape
                property: "rotation"
                value: 0
            }

            PropertyAction {
                target: xStarShape
                property: "rotation"
                value: 45
            }

        }

    }

    layer.effect: DropShadow {
        id: shadowEffect

        transparentBorder: true
        color: root.iconColor
        radius: Constants.sizeXs
        samples: 17
        spread: 0.1
    }

}
