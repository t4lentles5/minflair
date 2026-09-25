import QtQuick
import QtQuick.Layouts
import qs.Core.Components

Item {
    id: root

    property bool emptyVisible: false
    property bool searchEmptyVisible: false
    property string emptyText: "Empty"
    property string searchEmptyText: "No results found"

    Layout.fillWidth: true
    Layout.fillHeight: true

    GhostEmptyState {
        anchors.centerIn: parent
        visible: root.emptyVisible
        text: root.emptyText
        isAnimating: visible
    }

    GhostEmptyState {
        anchors.centerIn: parent
        visible: root.searchEmptyVisible
        text: root.searchEmptyText
        isAnimating: visible
    }

}
