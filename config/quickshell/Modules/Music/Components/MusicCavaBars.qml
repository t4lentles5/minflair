import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.Mpris
import qs.Core
import qs.Core.Components
import qs.Core.Services

Item {
    id: cavaBars

    property var cavaData: []
    property int barCount: 28
    property int barWidth: 3
    property real maxBarHeight: 18
    property real minBarHeight: Constants.size3Xs
    property int spacing: Constants.size3Xs

    Layout.fillWidth: true
    implicitHeight: maxBarHeight
    Layout.preferredHeight: maxBarHeight
    Layout.topMargin: Constants.size3Xs
    Layout.bottomMargin: 0

    Row {
        anchors.centerIn: parent
        spacing: cavaBars.spacing
        height: cavaBars.maxBarHeight

        Repeater {
            model: cavaBars.barCount

            Item {
                required property int index

                width: cavaBars.barWidth
                height: cavaBars.maxBarHeight

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: (parent.height - height) / 2
                    width: cavaBars.barWidth
                    height: {
                        if (!MprisService.isPlaying || SystemInfoService.powerProfile === "power-saver")
                            return cavaBars.minBarHeight;

                        let sampleIdx = Math.min(35, Math.floor(index * 35 / (cavaBars.barCount - 1)));
                        if (cavaBars.cavaData && cavaBars.cavaData.length > sampleIdx) {
                            let val = cavaBars.cavaData[sampleIdx];
                            return Math.max(cavaBars.minBarHeight, cavaBars.minBarHeight + (val / 100) * (cavaBars.maxBarHeight - cavaBars.minBarHeight));
                        }
                        return cavaBars.minBarHeight;
                    }
                    radius: cavaBars.barWidth / 2
                    color: Theme.accent

                    Behavior on height {
                        NumberAnimation {
                            duration: Math.max(0, Constants.animFast - 50)
                            easing.type: Easing.OutQuad
                        }

                    }

                }

            }

        }

    }

}
