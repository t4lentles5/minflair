import QtQuick
import "Styles/Convex"
import "Styles/Island"
import qs.Core
import qs.Core.Services

Item {
    id: mainBar

    required property var notificationService
    property var mainPanelWidget: null
    property string activeBarStyle: SettingsService.barStyle
    readonly property bool isCurrentIsland: activeBarStyle === "island"
    readonly property bool isCurrentConvex: activeBarStyle === "convex"
    // Use unified interface exposed by IBarStyle implementation
    readonly property QtObject currentStyleItem: {
        switch (mainBar.activeBarStyle) {
        case "island":
            return islandLoader.item;
        case "convex":
            return convexLoader.item;
        default:
            return islandLoader.item ? islandLoader.item : convexLoader.item;
        }
    }
    readonly property real leftWidth: currentStyleItem ? (currentStyleItem.leftWidth || 0) : 0
    readonly property real rightWidth: currentStyleItem ? (currentStyleItem.rightWidth || 0) : 0
    readonly property real centerX: currentStyleItem ? (currentStyleItem.centerX || 0) : 0
    readonly property real centerWidth: currentStyleItem ? (currentStyleItem.centerWidth || 0) : 0
    readonly property bool isOccupied: currentStyleItem ? (currentStyleItem.isOccupied || false) : false
    readonly property bool isExpanded: currentStyleItem ? (currentStyleItem.isExpanded || false) : false
    readonly property real currentHeight: (currentStyleItem && currentStyleItem.currentHeight > 0) ? currentStyleItem.currentHeight : 0
    readonly property bool isOverlayActive: currentStyleItem ? (currentStyleItem.isOverlayActive || false) : false
    readonly property bool isOpen: currentStyleItem ? (currentStyleItem.isOpen || false) : false
    readonly property bool needsFocus: currentStyleItem ? (currentStyleItem.needsFocus || false) : false
    readonly property real blockX: currentStyleItem ? (currentStyleItem.blockX || 0) : 0
    readonly property real blockY: currentStyleItem ? (currentStyleItem.blockY || 0) : 0
    readonly property real blockWidth: currentStyleItem ? (currentStyleItem.blockWidth || 0) : 0
    readonly property real blockHeight: currentStyleItem ? (currentStyleItem.blockHeight || 0) : 0

    function close() {
        if (currentStyleItem && typeof currentStyleItem.close === "function")
            currentStyleItem.close();

    }

    implicitWidth: currentStyleItem && currentStyleItem.implicitWidth > 0 ? currentStyleItem.implicitWidth : (BarStyleConfig.isPill(activeBarStyle) ? 180 : 0)

    Loader {
        id: islandLoader

        anchors.fill: parent
        active: mainBar.isCurrentIsland
        visible: active
        sourceComponent: islandComp
        enabled: visible
    }

    Loader {
        id: convexLoader

        anchors.fill: parent
        active: mainBar.isCurrentConvex
        visible: active
        sourceComponent: convexComp
        enabled: visible
    }

    Component {
        id: islandComp

        IslandBar {
            notificationService: mainBar.notificationService
            mainPanelWidget: mainBar.mainPanelWidget
        }

    }

    Component {
        id: convexComp

        ConvexBar {
            notificationService: mainBar.notificationService
            mainPanelWidget: mainBar.mainPanelWidget
        }

    }

}
