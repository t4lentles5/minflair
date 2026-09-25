import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components

Item {
    id: root

    property string label: ""
    property string description: ""
    property int labelSize: Constants.sizeSm
    property bool isSubSetting: false
    default property alias content: controlContainer.data

    implicitHeight: mainLayout.implicitHeight
    Layout.fillWidth: true

    RowLayout {
        id: mainLayout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Constants.sizeLg

        ColumnLayout {
            spacing: Constants.size3Xs
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter

            ThemedText {
                text: root.label
                customSize: root.labelSize
                color: root.enabled ? Theme.fg : Theme.muted
            }

            ThemedText {
                text: root.description
                color: Theme.muted
                visible: root.description !== ""
            }

        }

        Item {
            Layout.fillWidth: true
        }

        Item {
            id: controlContainer

            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            implicitWidth: childrenRect.width
            implicitHeight: childrenRect.height
        }

    }

}
