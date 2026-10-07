import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components

ColumnLayout {
    id: root

    property string title: ""
    property string category: ""
    property string subtitle: ""
    property bool showDivider: false
    default property alias actions: rightSlot.data

    Layout.fillWidth: true
    spacing: 0

    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 52
        Layout.leftMargin: Constants.sizeLg
        Layout.rightMargin: Constants.sizeLg
        Layout.topMargin: Constants.sizeLg
        Layout.bottomMargin: Constants.sizeLg

        RowLayout {
            anchors.fill: parent
            spacing: Constants.sizeMd

            ColumnLayout {
                spacing: Constants.size2Xs
                Layout.alignment: Qt.AlignVCenter
                Layout.maximumWidth: parent.width - (rightSlot.width > 0 ? rightSlot.width + Constants.sizeMd : 0)

                RowLayout {
                    spacing: Constants.sizeXs

                    ThemedText {
                        text: root.title
                        customSize: Constants.sizeXl
                        font.weight: Font.Bold
                        color: Theme.fg
                    }

                    ThemedText {
                        visible: root.category !== ""
                        text: "•"
                        customSize: Constants.sizeXl
                        color: Theme.accent
                    }

                    ThemedText {
                        visible: root.category !== ""
                        text: root.category
                        customSize: Constants.sizeSm
                        font.weight: Font.Bold
                        font.letterSpacing: 0.9
                        color: Theme.muted
                    }

                }

                ThemedText {
                    visible: root.subtitle !== ""
                    text: root.subtitle
                    customSize: 11
                    color: Theme.muted
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

            }

            Item {
                Layout.fillWidth: true
            }

            RowLayout {
                id: rightSlot

                Layout.alignment: Qt.AlignVCenter
                spacing: Constants.sizeSm
            }

        }

    }

    Divider {
        visible: root.showDivider
    }

}
