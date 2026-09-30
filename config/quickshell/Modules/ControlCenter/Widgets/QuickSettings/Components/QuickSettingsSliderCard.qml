import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components

Card {
    id: root

    property string label: ""
    property bool showMenuButton: false
    default property alias content: sliderContainer.data

    signal menuClicked()

    Layout.fillWidth: true
    contentPadding: Constants.sizeLg
    backgroundColor: Theme.bgSecondary

    ColumnLayout {
        anchors.fill: parent
        spacing: Constants.sizeMd

        RowLayout {
            Layout.fillWidth: true

            ThemedText {
                text: root.label
                font.bold: true
                customSize: Constants.sizeSm
                color: Theme.fg
                Layout.fillWidth: true
            }

        }

        Item {
            id: sliderContainer

            Layout.fillWidth: true
            Layout.preferredHeight: children.length > 0 ? children[0].implicitHeight : 28
        }

    }

}
