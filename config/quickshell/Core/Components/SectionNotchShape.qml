import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs.Core
import qs.Core.Services

Item {
    id: root

    property bool enableShadow: true
    property string mode: "center"
    property color color: Theme.bg
    property color borderColor: "transparent"
    property real borderWidth: 0
    property real flareWidth: 18
    property real flareHeight: 16
    property real bottomRadius: 16
    property real topBezel: 0
    readonly property real w: width
    readonly property real h: height

    function getPath(w, h) {
        if (w <= 0 || h <= 0)
            return "";

        let fw = Math.max(1, Math.min(root.flareWidth, w / 4));
        let fh = Math.max(1, Math.min(root.flareHeight, h / 2));
        let br = Math.max(0.1, Math.min(root.bottomRadius, h - fh));
        let tb = root.topBezel;
        let p = "";
        if (root.mode === "left") {
            p += `M 0 0 `;
            p += `L 0 ${h} `;
            p += `L ${w - fw - br} ${h} `;
            p += `C ${w - fw - br * 0.45} ${h}, ${w - fw} ${h - br * 0.45}, ${w - fw} ${h - br} `;
            if (h - br > fh + tb)
                p += `L ${w - fw} ${fh + tb} `;

            p += `C ${w - fw} ${fh * 0.45 + tb}, ${w - fw * 0.55} ${tb}, ${w} ${tb} `;
            if (tb > 0)
                p += `L ${w} 0 `;

            p += `Z`;
        } else if (root.mode === "right") {
            p += `M 0 0 `;
            if (tb > 0)
                p += `L 0 ${tb} `;

            p += `C ${fw * 0.55} ${tb}, ${fw} ${fh * 0.45 + tb}, ${fw} ${fh + tb} `;
            if (h - br > fh + tb)
                p += `L ${fw} ${h - br} `;

            p += `C ${fw} ${h - br * 0.45}, ${fw + br * 0.45} ${h}, ${fw + br} ${h} `;
            p += `L ${w} ${h} `;
            p += `L ${w} 0 `;
            p += `Z`;
        } else {
            p += `M 0 0 `;
            if (tb > 0)
                p += `L 0 ${tb} `;

            p += `C ${fw * 0.55} ${tb}, ${fw} ${fh * 0.45 + tb}, ${fw} ${fh + tb} `;
            if (h - br > fh + tb)
                p += `L ${fw} ${h - br} `;

            p += `C ${fw} ${h - br * 0.45}, ${fw + br * 0.45} ${h}, ${fw + br} ${h} `;
            p += `L ${w - fw - br} ${h} `;
            p += `C ${w - fw - br * 0.45} ${h}, ${w - fw} ${h - br * 0.45}, ${w - fw} ${h - br} `;
            if (h - br > fh + tb)
                p += `L ${w - fw} ${fh + tb} `;

            p += `C ${w - fw} ${fh * 0.45 + tb}, ${w - fw * 0.55} ${tb}, ${w} ${tb} `;
            if (tb > 0)
                p += `L ${w} 0 `;

            p += `Z`;
        }
        return p;
    }

    Shape {
        id: visibleShape

        anchors.fill: parent
        layer.enabled: root.enableShadow && HyprlandService.hyprShadow && opacity > 0.001

        ShapePath {
            strokeWidth: root.borderWidth
            strokeColor: root.borderColor
            fillColor: root.color

            PathSvg {
                path: root.getPath(root.w, root.h)
            }

        }

        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.alpha(Theme.shadow, 0.85)
            blurMax: 16
            shadowBlur: 3
            shadowVerticalOffset: 0
            shadowHorizontalOffset: 0
        }

    }

    Behavior on color {
        ColorAnimation {
            duration: Constants.animNormal
        }

    }

}
