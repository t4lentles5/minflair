import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Shapes
import qs.Core
import qs.Core.Services

Item {
    id: root

    property int iconSize: 32
    property color iconColor: Theme.accent
    property string plusStarPath: "M 11.6 2.5 Q 12 1.2 12.4 2.5 L 14 10 L 21.5 11.6 Q 22.8 12 21.5 12.4 L 14 14 L 12.4 21.5 Q 12 22.8 11.6 21.5 L 10 14 L 2.5 12.4 Q 1.2 12 2.5 11.6 L 10 10 Z"
    readonly property int scaledIconSize: Math.round(iconSize * SettingsService.fontScale)
    property bool enableIntroAnim: true
    property bool enableIntervalAnim: true

    width: scaledIconSize
    height: scaledIconSize
    implicitWidth: scaledIconSize
    implicitHeight: scaledIconSize
    layer.enabled: true

    Item {
        id: starContainer

        width: 24
        height: 24
        scale: root.scaledIconSize / 24
        rotation: 45
        anchors.centerIn: parent
        enabled: false

        Item {
            id: mainStarShape

            width: 24
            height: 24
            transformOrigin: Item.Center
            rotation: 0

            Shape {
                width: 24
                height: 24
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

            width: 24
            height: 24
            transformOrigin: Item.Center
            rotation: 45
            scale: 1

            Shape {
                width: 24
                height: 24
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
                duration: 200
            }

            ParallelAnimation {
                ParallelAnimation {
                    NumberAnimation {
                        target: mainStarShape
                        property: "scale"
                        to: 1
                        duration: 900
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.2
                    }

                    NumberAnimation {
                        target: mainStarShape
                        property: "rotation"
                        to: 0
                        duration: 900
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.2
                    }

                }

                SequentialAnimation {
                    PauseAnimation {
                        duration: 150
                    }

                    ParallelAnimation {
                        NumberAnimation {
                            target: xStarShape
                            property: "scale"
                            to: 1
                            duration: 900
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.2
                        }

                        NumberAnimation {
                            target: xStarShape
                            property: "rotation"
                            to: 45
                            duration: 900
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
                duration: 5000
            }

            ParallelAnimation {
                NumberAnimation {
                    target: mainStarShape
                    property: "rotation"
                    from: 0
                    to: 90
                    duration: 1200
                    easing.type: Easing.InOutBack
                    easing.overshoot: 1.2
                }

                NumberAnimation {
                    target: xStarShape
                    property: "rotation"
                    from: 45
                    to: -45
                    duration: 1200
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
        radius: 8
        samples: 17
        spread: 0.1
    }

}
