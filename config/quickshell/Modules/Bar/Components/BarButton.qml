import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services

Rectangle {
    id: root

    property var widget
    property string popupId: ""
    property string icon: ""
    property int iconSize: Constants.sizeLg
    property int fontSize: Constants.sizeSm
    property color iconColor: Theme.fg

    color: "transparent"
    radius: Constants.sizeLg
    implicitWidth: svgIcon.implicitWidth
    implicitHeight: svgIcon.implicitHeight

    SvgIcon {
        id: svgIcon

        anchors.centerIn: parent
        icon: root.icon
        iconSize: root.iconSize
        flat: true
        scale: mouseArea.pressed ? 0.9 : (mouseArea.containsMouse ? 1.1 : 1)
        iconColor: mouseArea.containsMouse ? Theme.accent : root.iconColor

        MouseArea {
            id: mouseArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (widget)
                    widget.isOpen = !widget.isOpen;
                else if (popupId !== "")
                    AppState.togglePopup(popupId);
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: Constants.animFast
                easing.type: Easing.OutQuad
            }

        }

        Behavior on iconColor {
            ColorAnimation {
                duration: Constants.animFast
            }

        }

    }

}
