import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.Mpris
import qs.Core
import qs.Core.Components
import qs.Core.Services

RowLayout {
    id: cavaBars

    property var cavaData: []

    Layout.fillWidth: true
    Layout.preferredHeight: 22
    Layout.topMargin: Constants.sizeSm
    Layout.bottomMargin: Constants.sizeSm
    spacing: 3

    Item {
        Layout.fillWidth: true
    }

    Repeater {
        model: 28

        Item {
            required property int index

            Layout.preferredWidth: 3
            Layout.preferredHeight: 22

            Rectangle {
                y: (parent.height - height) / 2
                anchors.horizontalCenter: parent.horizontalCenter
                width: 3
                height: {
                    if (!MprisService.isPlaying)
                        return 3;

                    if (cavaBars.cavaData && cavaBars.cavaData.length > index)
                        return Math.max(3, 3 + (cavaBars.cavaData[index] / 100) * 18);

                    return 3;
                }
                radius: 1.5
                color: Theme.accent

                Behavior on height {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutCubic
                    }

                }

            }

        }

    }

    Item {
        Layout.fillWidth: true
    }

}
