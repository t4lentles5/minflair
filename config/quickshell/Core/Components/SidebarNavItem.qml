import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components

// A navigation row inside an app sidebar. It carries the spacing every
// sidebar uses, so the Settings, Keybinds and Package Manager sidebars stay
// visually identical.
Item {
    id: root

    property string iconName: ""
    property string labelText: ""
    property string statusText: ""
    property bool isActive: false

    signal rowClicked()

    Layout.fillWidth: true
    Layout.leftMargin: Constants.sizeSm
    Layout.rightMargin: Constants.sizeSm
    // Kept at the height the sidebars have always used, so the rows do not move.
    Layout.preferredHeight: 34

    SidebarNavRow {
        anchors.fill: parent
        iconName: root.iconName
        labelText: root.labelText
        statusText: root.statusText
        isActive: root.isActive
        onRowClicked: root.rowClicked()
    }

}
