import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs.Core
import qs.Core.Services

Item {
    id: root

    property bool enableShadow: false
    property color color: Theme.bg
    property color borderColor: "transparent"
    property int borderWidth: 0
    property real cornerRadius: Constants.size2Xl
    property int edge: Qt.BottomEdge // Qt.TopEdge, Qt.BottomEdge, Qt.RightEdge, Qt.LeftEdge
    readonly property real rx: cornerRadius
    readonly property real ry: Math.max(0.1, Math.min(cornerRadius, height / 2.1))
    readonly property real w: width
    readonly property real h: height

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        layer.enabled: root.enableShadow && HyprlandService.hyprShadow
        layer.smooth: root.enableShadow
        layer.samples: root.enableShadow ? 4 : 1

        ShapePath {
            strokeWidth: root.borderWidth
            strokeColor: root.borderColor
            fillColor: root.color

            PathSvg {
                path: {
                    let w = root.w;
                    let h = root.h;
                    let rx = root.rx;
                    let ry = root.ry;
                    if (w <= 0 || h <= 0)
                        return "";

                    if (root.edge === Qt.RightEdge) {
                        let pRight = `M 0 0 `;
                        pRight += `A ${rx} ${ry} 0 0 1 ${rx} ${ry} `;
                        pRight += `L ${rx} ${Math.max(0, h - ry)} `;
                        pRight += `A ${rx} ${ry} 0 0 1 0 ${h} `;
                        pRight += `L ${Math.max(0, w - rx)} ${h} `;
                        pRight += `A ${rx} ${ry} 0 0 0 ${w} ${Math.max(0, h - ry)} `;
                        pRight += `L ${w} ${ry} `;
                        pRight += `A ${rx} ${ry} 0 0 0 ${Math.max(0, w - rx)} 0 `;
                        pRight += `Z`;
                        return pRight;
                    } else if (root.edge === Qt.BottomEdge) {
                        return `M 0 ${h} ` + `A ${rx} ${ry} 0 0 0 ${rx} ${Math.max(0, h - ry)} ` + `L ${rx} ${ry} ` + `A ${rx} ${ry} 0 0 1 ${2 * rx} 0 ` + `L ${Math.max(2 * rx, w - 2 * rx)} 0 ` + `A ${rx} ${ry} 0 0 1 ${Math.max(rx, w - rx)} ${ry} ` + `L ${Math.max(rx, w - rx)} ${Math.max(0, h - ry)} ` + `A ${rx} ${ry} 0 0 0 ${w} ${h} Z`;
                    } else if (root.edge === Qt.TopEdge) {
                        let pTop = `M 0 0 `;
                        pTop += `A ${rx} ${ry} 0 0 1 ${rx} ${ry} `;
                        pTop += `L ${rx} ${Math.max(0, h - ry)} `;
                        pTop += `A ${rx} ${ry} 0 0 0 ${2 * rx} ${h} `;
                        pTop += `L ${Math.max(2 * rx, w - 2 * rx)} ${h} `;
                        pTop += `A ${rx} ${ry} 0 0 0 ${Math.max(rx, w - rx)} ${Math.max(0, h - ry)} `;
                        pTop += `L ${Math.max(rx, w - rx)} ${ry} `;
                        pTop += `A ${rx} ${ry} 0 0 1 ${w} 0 Z`;
                        return pTop;
                    } else if (root.edge === Qt.LeftEdge) {
                        let pLeft = `M ${w} 0 `;
                        pLeft += `A ${rx} ${ry} 0 0 0 ${w - rx} ${ry} `;
                        pLeft += `L ${w - rx} ${Math.max(0, h - ry)} `;
                        pLeft += `A ${rx} ${ry} 0 0 0 ${w} ${h} `;
                        pLeft += `L ${rx} ${h} `;
                        pLeft += `A ${rx} ${ry} 0 0 1 0 ${Math.max(0, h - ry)} `;
                        pLeft += `L 0 ${ry} `;
                        pLeft += `A ${rx} ${ry} 0 0 1 ${rx} 0 `;
                        pLeft += `Z`;
                        return pLeft;
                    }
                }
            }

        }

        layer.effect: MultiEffect {
            shadowEnabled: root.enableShadow && HyprlandService.hyprShadow && !DisplayProfileService.gameModeActive && (SystemInfoService.powerProfile !== "power-saver")
            shadowColor: Qt.rgba(Theme.shadow.r, Theme.shadow.g, Theme.shadow.b, Theme.isDark ? 1 : Math.min(1, Theme.shadow.a * 1.6))
            blurMax: HyprlandService.hyprShadowRange
            shadowBlur: 1
            shadowVerticalOffset: 0
            shadowHorizontalOffset: 0
        }

    }

}
