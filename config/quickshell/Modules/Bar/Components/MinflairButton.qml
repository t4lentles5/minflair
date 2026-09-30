import QtQuick
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Bar

BarButton {
    id: root

    property int iconSize: Constants.size2Xl + 4
    property var customClickHandler: null
    property bool enableIntervalAnim: true

    implicitWidth: minflair.implicitWidth
    implicitHeight: minflair.implicitHeight
    height: implicitHeight

    AnimatedMinflair {
        id: minflair

        anchors.centerIn: parent
        iconSize: root.iconSize
        enableIntervalAnim: root.enableIntervalAnim
        scale: mouseArea.pressed ? 0.9 : (mouseArea.containsMouse ? 1.1 : 1)

        MouseArea {
            id: mouseArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: (mouse) => {
                if (root.customClickHandler) {
                    root.customClickHandler(mouse);
                    return ;
                }
                AppState.togglePopup("dashboard");
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: Constants.animFast
                easing.type: Easing.OutQuad
            }

        }

    }

}
