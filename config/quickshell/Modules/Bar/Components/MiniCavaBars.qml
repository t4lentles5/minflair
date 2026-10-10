import QtQuick
import qs.Core
import qs.Core.Services

Row {
    id: root

    property int barCount: 4
    property real barWidth: Constants.size3Xs
    property real maxBarHeight: Constants.sizeLg
    property real minBarHeight: Constants.size3Xs + 1
    property real barRadius: Constants.size3Xs - 1
    property color barColor: Theme.accent
    property bool isPlaying: MprisService.isPlaying

    function getBandValue(bandIdx) {
        if (!CavaService.cavaData || CavaService.cavaData.length === 0)
            return 0;

        let total = CavaService.cavaData.length;
        let bucketSize = Math.max(1, Math.floor(total / root.barCount));
        let start = bandIdx * bucketSize;
        let end = (bandIdx === root.barCount - 1) ? total : Math.min(total, start + bucketSize);
        let maxVal = 0;
        let sum = 0;
        for (let i = start; i < end; i++) {
            let v = CavaService.cavaData[i] || 0;
            if (v > maxVal)
                maxVal = v;

            sum += v;
        }
        let count = end - start;
        let avg = count > 0 ? (sum / count) : 0;
        return Math.round(maxVal * 0.7 + avg * 0.3);
    }

    spacing: 2
    height: maxBarHeight
    width: implicitWidth

    Repeater {
        model: root.barCount

        Item {
            required property int index

            width: root.barWidth
            height: root.maxBarHeight

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: (parent.height - height) / 2
                width: root.barWidth
                height: {
                    if (!root.isPlaying || SystemInfoService.powerProfile === "power-saver")
                        return root.minBarHeight;

                    let v = root.getBandValue(index);
                    return Math.max(root.minBarHeight, Math.min(root.maxBarHeight, root.minBarHeight + (v / 100) * (root.maxBarHeight - root.minBarHeight)));
                }
                radius: root.barRadius
                color: root.barColor

                Behavior on height {
                    NumberAnimation {
                        duration: Constants.animUltraFast
                        easing.type: Easing.OutQuad
                    }

                }

            }

        }

    }

}
