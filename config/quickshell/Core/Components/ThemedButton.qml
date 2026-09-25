import QtQuick
import qs.Core

Rectangle {
    id: root

    property string text: ""
    property color textColor: Theme.accent
    property bool disabled: false
    property alias mouseArea: buttonMouse

    signal clicked()

    implicitWidth: buttonLayout.implicitWidth + Constants.sizeLg * 2
    implicitHeight: buttonLayout.implicitHeight + Constants.sizeLg
    radius: Constants.sizeLg
    color: root.disabled ? Theme.bgSecondary : (buttonMouse.containsMouse ? Theme.bgTertiary : Theme.bgSecondary)
    scale: (buttonMouse.pressed && !root.disabled) ? 0.95 : 1
    border.width: root.disabled ? 0 : 1
    border.color: root.disabled ? Theme.muted : Theme.accent

    Row {
        id: buttonLayout

        anchors.centerIn: parent
        spacing: Constants.sizeXs

        ThemedText {
            text: root.text
            font.bold: true
            color: root.disabled ? Theme.muted : root.textColor
            visible: root.text !== ""
            anchors.verticalCenter: parent.verticalCenter
        }

    }

    MouseArea {
        id: buttonMouse

        anchors.fill: parent
        hoverEnabled: !root.disabled
        cursorShape: root.disabled ? Qt.ArrowCursor : Qt.PointingHandCursor
        onClicked: {
            if (!root.disabled)
                root.clicked();

        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: Constants.animUltraFast
        }

    }

    Behavior on color {
        ColorAnimation {
            duration: Constants.animFast
        }

    }

    Behavior on border.width {
        NumberAnimation {
            duration: Constants.animFast
        }

    }

}
