import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Bar.Components

Item {
    id: root

    required property var notificationService
    property var mainPanelWidget: null
    readonly property real leftWidth: leftSection.width
    readonly property real rightWidth: rightSection.width
    readonly property real centerX: centerSlot.x
    readonly property real centerWidth: centerSlot.width
    readonly property bool isOccupied: false
    readonly property bool isExpanded: true
    readonly property string activeBarStyle: "minflair"

    anchors.fill: parent

    Rectangle {
        id: barShape

        anchors.fill: parent
        radius: Constants.size2Xl
        color: Theme.bg
        border.width: 0
        antialiasing: true
        border.color: "transparent"

        Behavior on color {
            ColorAnimation {
                duration: Constants.animNormal
            }

        }

    }

    BarLeftSection {
        id: leftSection

        anchors.left: parent.left
        mainPanelWidget: root.mainPanelWidget
        notificationService: root.notificationService
        mainBar: root
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
    }

}
