import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs.Core
import qs.Core.Components
import qs.Core.Services

Item {
    id: root

    property bool enableShadow: true
    property color color: Theme.bg
    property color borderColor: "transparent"
    property real borderWidth: 0
    property real flareWidth: 18
    property real flareHeight: 16
    property real bottomRadius: 16
    property real centerBottomRadius: bottomRadius
    property real topBezel: 8
    property real baseHeight: 44
    property real leftW: 0
    property real centerX: 0
    property real centerW: 0
    property real rightW: 0
    property real centerHeight: height

    function getPath(w, h, lW, cX, cW, rW, tb, fw, fh, br, cH, baseH, cbr) {
        if (w <= 0 || h <= 0)
            return "";

        let bh = baseH > 0 ? baseH : h;
        let centerR = (cbr !== undefined && cbr > 0) ? cbr : br;
        let p = `M 0 0 `;
        // 1. Left notch
        p += `L 0 ${bh} `;
        p += `L ${lW - fw - br} ${bh} `;
        p += `C ${lW - fw - br * 0.45} ${bh}, ${lW - fw} ${bh - br * 0.45}, ${lW - fw} ${bh - br} `;
        if (bh - br > fh + tb)
            p += `L ${lW - fw} ${fh + tb} `;

        p += `C ${lW - fw} ${fh * 0.45 + tb}, ${lW - fw * 0.55} ${tb}, ${lW} ${tb} `;
        // 2. Bridge 1
        p += `L ${cX} ${tb} `;
        // 3. Flare into center notch
        p += `C ${cX + fw * 0.55} ${tb}, ${cX + fw} ${fh * 0.45 + tb}, ${cX + fw} ${fh + tb} `;
        if (cH - centerR > fh + tb)
            p += `L ${cX + fw} ${cH - centerR} `;

        p += `C ${cX + fw} ${cH - centerR * 0.45}, ${cX + fw + centerR * 0.45} ${cH}, ${cX + fw + centerR} ${cH} `;
        // 4. Center notch bottom
        p += `L ${cX + cW - fw - centerR} ${cH} `;
        p += `C ${cX + cW - fw - centerR * 0.45} ${cH}, ${cX + cW - fw} ${cH - centerR * 0.45}, ${cX + cW - fw} ${cH - centerR} `;
        if (cH - centerR > fh + tb)
            p += `L ${cX + cW - fw} ${fh + tb} `;

        p += `C ${cX + cW - fw} ${fh * 0.45 + tb}, ${cX + cW - fw * 0.55} ${tb}, ${cX + cW} ${tb} `;
        // 5. Bridge 2
        let rX = w - rW;
        p += `L ${rX} ${tb} `;
        // 6. Flare into right notch
        p += `C ${rX + fw * 0.55} ${tb}, ${rX + fw} ${fh * 0.45 + tb}, ${rX + fw} ${fh + tb} `;
        if (bh - br > fh + tb)
            p += `L ${rX + fw} ${bh - br} `;

        p += `C ${rX + fw} ${bh - br * 0.45}, ${rX + fw + br * 0.45} ${bh}, ${rX + fw + br} ${bh} `;
        // 7. Right notch and close
        p += `L ${w} ${bh} `;
        p += `L ${w} 0 `;
        p += `Z`;
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
                path: root.getPath(root.width, root.height, root.leftW, root.centerX, root.centerW, root.rightW, root.topBezel, root.flareWidth, root.flareHeight, root.bottomRadius, root.centerHeight, root.baseHeight, root.centerBottomRadius)
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
