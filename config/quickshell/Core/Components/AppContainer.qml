import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Core
import qs.Core.Components

Item {
    id: root

    default property alias content: contentLayout.data
    property int contentPadding: Constants.sizeLg

    Layout.fillWidth: true
    Layout.fillHeight: true

    Flickable {
        id: flickable

        anchors.fill: parent
        anchors.margins: root.contentPadding
        clip: true
        interactive: true
        contentWidth: width
        contentHeight: mainCard.implicitHeight

        ColumnLayout {
            id: mainCard

            width: flickable.width

            ColumnLayout {
                id: contentLayout

                Layout.fillWidth: true
                spacing: Constants.sizeLg
            }

        }

        ScrollIndicator.vertical: ScrollIndicator {
            parent: flickable.parent
            anchors.top: flickable.top
            anchors.bottom: flickable.bottom
            anchors.right: flickable.right
        }

    }

}
