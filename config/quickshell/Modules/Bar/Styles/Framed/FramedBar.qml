import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Services
import qs.Modules.Bar.Components

Item {
    id: root

    property var notificationService: null
    property var mainPanelWidget: null
    readonly property real leftWidth: leftSection.width
    readonly property real rightWidth: rightSection.width
    readonly property real centerX: centerSlot.x
    readonly property real centerWidth: centerSlot.width
    readonly property bool isOccupied: false
    readonly property bool isExpanded: true
    readonly property string activeBarStyle: "framed"

    anchors.fill: parent

    Rectangle {
        anchors.fill: parent
        color: Theme.bg
        z: -1
    }

    BarLeftSection {
        id: leftSection

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        mainPanelWidget: root.mainPanelWidget
        notificationService: root.notificationService
        mainBar: root
        contentMargin: Constants.sizeXs
    }

    BarCenterSection {
        id: centerSlot

        anchors.centerIn: parent
        mainBar: root
    }

    BarRightSection {
        id: rightSection

        anchors.right: parent.right
        notificationService: root.notificationService
        mainBar: root
        contentMargin: Constants.sizeXs
    }

}
