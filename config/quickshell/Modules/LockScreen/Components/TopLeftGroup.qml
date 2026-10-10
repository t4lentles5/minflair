import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components

Item {
    id: root

    implicitWidth: layout.implicitWidth + Constants.sizeXl
    implicitHeight: 36

    ThemedShadow {
        anchors.fill: pillBg
        radius: pillBg.radius
        active: true
        opacity: Theme.isDark ? 0.5 : 0.25
    }

    Rectangle {
        id: pillBg

        anchors.fill: parent
        radius: height / 2
        color: Theme.bg
        border.color: Theme.border
        border.width: 1

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: parent.radius
            color: Theme.bgSecondary
        }

        RowLayout {
            id: layout

            anchors.centerIn: parent
            spacing: Constants.sizeSm

            SvgIcon {
                icon: "lock"
                iconSize: Constants.sizeMd
                iconColor: Theme.accent
                flat: true
            }

            ThemedText {
                text: "LOCKED"
                font.letterSpacing: Constants.size3Xs
                font.bold: true
                customSize: 11
                color: Theme.fg
            }

        }

    }

}
