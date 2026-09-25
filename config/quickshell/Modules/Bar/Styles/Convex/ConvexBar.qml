import QtQuick
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Bar
import qs.Modules.Bar.Components

Item {
    id: root

    property var notificationService: null
    property var mainPanelWidget: null
    readonly property real baseBarHeight: BarStyleConfig.barHeight("convex")
    readonly property real leftWidth: leftSection.width
    readonly property real rightWidth: rightSection.width
    readonly property real centerWidth: convexCenter.currentWidth
    readonly property real centerHeight: convexCenter.currentHeight
    readonly property real centerX: Math.round((root.width - centerWidth) / 2)
    readonly property bool isOccupied: convexCenter.isOccupied
    readonly property bool isExpanded: true
    readonly property string activeBarStyle: "convex"

    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: root.baseBarHeight

    ConvexShape {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: Math.max(root.baseBarHeight, root.centerHeight)
        baseHeight: root.baseBarHeight
        leftW: root.leftWidth
        centerX: root.centerX
        centerW: root.centerWidth
        centerHeight: root.centerHeight
        rightW: root.rightWidth
        z: -1
        enableShadow: false
        centerBottomRadius: convexCenter.currentRadius
    }

    BarLeftSection {
        id: leftSection

        anchors.left: parent.left
        anchors.top: parent.top
        height: root.baseBarHeight
        mainPanelWidget: root.mainPanelWidget
        notificationService: root.notificationService
        sidePadding: 36
        mainBar: root
        contentMargin: Constants.sizeXs
    }

    ConvexCenter {
        id: convexCenter

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        notificationService: root.notificationService
        mainPanelWidget: root.mainPanelWidget
        mainBar: root
        showNotchShape: false
        extraPadding: 32
    }

    BarRightSection {
        id: rightSection

        anchors.right: parent.right
        anchors.top: parent.top
        height: root.baseBarHeight
        notificationService: root.notificationService
        sidePadding: 36
        mainBar: root
        contentMargin: Constants.sizeXs
    }

}
