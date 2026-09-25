import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Core
import qs.Core.Components

Rectangle {
    property string title: ""
    property var itemsModel: []
    property int columnSpan: 1
    property var visibleItems: {
        let arr = [];
        for (let i = 0; i < itemsModel.length; i++) {
            if (itemsModel[i].val !== "" && itemsModel[i].val !== "None")
                arr.push(itemsModel[i]);

        }
        return arr;
    }

    Layout.fillWidth: true
    Layout.alignment: Qt.AlignTop
    Layout.columnSpan: columnSpan
    implicitHeight: contentCol.implicitHeight + Constants.sizeLg * 2
    color: Theme.bgSecondary
    radius: Constants.sizeMd
    visible: visibleItems.length > 0

    ColumnLayout {
        id: contentCol

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Constants.sizeLg
        spacing: Constants.sizeMd

        ThemedText {
            text: title
            font.bold: true
            customSize: Constants.sizeMd
            color: Theme.fg
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Constants.sizeSm

            Repeater {
                model: visibleItems

                delegate: RowLayout {
                    Layout.fillWidth: true

                    ThemedText {
                        text: modelData.keyName
                        color: Theme.muted
                        customSize: Constants.sizeSm
                        Layout.preferredWidth: 120
                        Layout.alignment: Qt.AlignTop
                    }

                    Item {
                        Layout.fillWidth: true
                        implicitHeight: Math.max(simpleVal.implicitHeight, chipsFlow.implicitHeight)
                        Layout.alignment: Qt.AlignTop

                        ThemedText {
                            id: simpleVal

                            visible: !modelData.isChips
                            anchors.right: parent.right
                            anchors.left: parent.left
                            text: modelData.val || "None"
                            color: modelData.isLink ? Theme.accent : Theme.fg
                            customSize: Constants.sizeSm
                            wrapMode: Text.Wrap
                            horizontalAlignment: Qt.AlignRight
                        }

                        Flow {
                            id: chipsFlow

                            visible: modelData.isChips
                            anchors.right: parent.right
                            anchors.left: parent.left
                            spacing: Constants.sizeXs
                            layoutDirection: Qt.RightToLeft

                            Repeater {
                                model: modelData.val ? modelData.val.split(/\s+/) : []

                                delegate: Rectangle {
                                    visible: modelData.trim() !== ""
                                    width: chipText.implicitWidth + Constants.sizeSm * 2
                                    height: chipText.implicitHeight + Constants.sizeXs * 2
                                    radius: Constants.sizeXs
                                    color: Theme.bgTertiary

                                    ThemedText {
                                        id: chipText

                                        anchors.centerIn: parent
                                        text: modelData
                                        customSize: Constants.sizeSm
                                        color: Theme.fg
                                    }

                                }

                            }

                        }

                    }

                }

            }

        }

    }

}
