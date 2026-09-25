import QtQuick
import QtQuick.Shapes
import qs.Core

Shape {
    id: root

    property real targetWidth: 0
    property real targetHeight: 0
    property real currentRadius: Constants.size2Xl
    property color shapeColor: Theme.bg

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    width: {
        let w = Math.round(targetWidth);
        return (w % 2 === 0) ? w : (w + 1);
    }
    height: Math.round(targetHeight)

    ShapePath {
        strokeWidth: 0
        strokeColor: "transparent"
        fillColor: root.shapeColor

        PathSvg {
            path: {
                let w = root.width;
                let h = root.height;
                let r = root.currentRadius;
                if (w <= 0 || h <= 0)
                    return "";

                r = Math.max(0, Math.min(r, Math.min(w / 2, h / 2)));
                if (r <= 0.5)
                    return `M 0 0 L ${w} 0 L ${w} ${h} L 0 ${h} Z`;

                let k = r * 0.552285;
                return `M ${r} 0 ` + `L ${w - r} 0 ` + `C ${w - r + k} 0, ${w} ${r - k}, ${w} ${r} ` + `L ${w} ${h - r} ` + `C ${w} ${h - r + k}, ${w - r + k} ${h}, ${w - r} ${h} ` + `L ${r} ${h} ` + `C ${r - k} ${h}, 0 ${h - r + k}, 0 ${h - r} ` + `L 0 ${r} ` + `C 0 ${r - k}, ${r - k} 0, ${r} 0 Z`;
            }
        }

    }

    Behavior on shapeColor {
        ColorAnimation {
            duration: Constants.animNormal
        }

    }

}
