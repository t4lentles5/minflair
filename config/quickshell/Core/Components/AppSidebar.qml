import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Core
import qs.Core.Components

Rectangle {
    id: root

    property string title: ""
    property string subtitle: ""
    property int sidebarWidth: 250
    property alias contentSpacing: contentCol.spacing
    default property alias content: contentCol.data

    Layout.preferredWidth: root.sidebarWidth
    Layout.minimumWidth: root.sidebarWidth
    Layout.maximumWidth: root.sidebarWidth
    Layout.fillHeight: true
    color: Theme.bg

    // Separator line on the right edge
    Divider {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        vertical: true
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Top Header
        ColumnLayout {
            Layout.fillWidth: true
            Layout.margins: Constants.sizeLg
            spacing: Constants.size2Xs
            visible: root.title !== "" || root.subtitle !== ""

            ThemedText {
                visible: root.title !== ""
                text: root.title
                customSize: Constants.sizeLg
                font.weight: Font.Bold
                font.letterSpacing: 1.5
                color: Theme.fg
            }

            ThemedText {
                visible: root.subtitle !== ""
                text: root.subtitle
                customSize: Constants.sizeXs + 2
                font.weight: Font.DemiBold
                font.letterSpacing: 1
                color: Theme.muted
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

        }

        // Scrollable Navigation Area
        Flickable {
            id: navFlickable

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: contentCol.implicitHeight + Constants.sizeLg

            ColumnLayout {
                id: contentCol

                width: navFlickable.width
                spacing: Constants.size3Xs

                Item {
                    Layout.preferredHeight: Constants.size3Xs
                }

            }

            ScrollBar.vertical: ScrollBar {
                parent: navFlickable
                anchors.right: navFlickable.right
                anchors.top: navFlickable.top
                anchors.bottom: navFlickable.bottom
                policy: ScrollBar.AsNeeded
                width: Constants.size2Xs
            }

        }

    }

}
