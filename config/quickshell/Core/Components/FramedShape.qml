import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs.Core
import qs.Core.Services

Item {
    id: root

    property bool enableShadow: !isFramed
    property color color: Theme.bg
    property color borderColor: "transparent"
    property int borderWidth: 0
    property real cornerRadius: Constants.size2Xl
    property bool positionAtRight: false
    property int edge: positionAtRight ? Qt.RightEdge : Qt.TopEdge // Qt.TopEdge, Qt.BottomEdge, Qt.RightEdge
    property bool isFramed: SettingsService.barFramedMode || SettingsService.barConvexMode || SettingsService.barMinflairMode
    readonly property real rx: cornerRadius
    readonly property real ry: Math.max(0.1, Math.min(cornerRadius, height / 2.1))
    readonly property real w: width
    readonly property real h: height

    Shape {
        anchors.fill: parent
        layer.enabled: root.enableShadow && HyprlandService.hyprShadow

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

                    if (root.positionAtRight) {
                        let r_x = Math.min(rx, w / 2.5);
                        let r_y = Math.min(ry, h / 2.5);
                        let r_bl = Math.min(rx, (h - r_y) / 2);
                        let r_tr = Math.min(Constants.size4Xl, w / 2, h / 2);
                        let p = `M 0 0 `;
                        p += `A ${r_x} ${r_y} 0 0 1 ${r_x} ${r_y} `;
                        p += `L ${r_x} ${Math.max(r_y, h - r_y - r_bl)} `;
                        p += `A ${r_bl} ${r_bl} 0 0 0 ${r_x + r_bl} ${Math.max(r_y, h - r_y)} `;
                        p += `L ${Math.max(r_x + r_bl, w - r_x)} ${Math.max(r_y, h - r_y)} `;
                        p += `A ${r_x} ${r_y} 0 0 1 ${w} ${h} `;
                        p += `L ${w} ${r_tr} `;
                        p += `A ${r_tr} ${r_tr} 0 0 0 ${w - r_tr} 0 `;
                        p += `L 0 0 `;
                        p += `Z`;
                        return p;
                    }
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
            shadowEnabled: true
            shadowColor: Qt.alpha(Theme.shadow, 0.85)
            blurMax: 16
            shadowBlur: 1
            shadowVerticalOffset: 0
            shadowHorizontalOffset: 0
        }

    }

}
