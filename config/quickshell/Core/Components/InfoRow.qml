import QtQuick
import QtQuick.Layouts
import qs.Core

Item {
    id: root

    property string icon: ""
    property string label: ""
    property string value: ""
    property color labelColor: Theme.fg

    implicitHeight: Constants.size2Xl + 4
    Layout.fillWidth: true

    HoverHandler {
        id: rowHover
    }

    RowLayout {
        anchors.fill: parent
        spacing: Constants.sizeSm

        SvgIcon {
            icon: root.icon
            flat: true
            iconColor: Theme.accent
            iconSize: Constants.sizeMd
            visible: root.icon !== ""
        }

        ThemedText {
            text: root.label
            color: root.labelColor
            Layout.fillWidth: true
        }

        ThemedText {
            text: root.value
            font.bold: true
            color: Theme.fg
        }

    }

}
