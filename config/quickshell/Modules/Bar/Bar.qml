import QtQuick
import "Styles/Convex"
import "Styles/Island"
import "Styles/Minflair"
import "Styles/Notch"
import qs.Core
import qs.Core.Services

Item {
    id: mainBar

    required property var notificationService
    property var mainPanelWidget: null
    property string activeBarStyle: ""
    property bool loadMinflair: activeBarStyle === "minflair" || (activeBarStyle === "" && SettingsService.barStyle === "minflair")
    property bool loadIsland: activeBarStyle === "island"
    property bool loadNotch: activeBarStyle === "notch"
    property bool loadConvex: activeBarStyle === "convex"
    // Use unified interface exposed by IBarStyle implementation
    readonly property QtObject currentStyleItem: {
        switch (mainBar.activeBarStyle) {
        case "island":
            return islandLoader.item;
        case "notch":
            return notchLoader.item;
        case "convex":
            return convexLoader.item;
        default:
            return minflairLoader.item;
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
    // Geometry exposed for popupSurface mask
    readonly property real blockX: currentStyleItem ? (currentStyleItem.blockX || 0) : 0
    readonly property real blockY: currentStyleItem ? (currentStyleItem.blockY || 0) : 0
    readonly property real blockWidth: currentStyleItem ? (currentStyleItem.blockWidth || 0) : 0
    readonly property real blockHeight: currentStyleItem ? (currentStyleItem.blockHeight || 0) : 0

    function close() {
        if (currentStyleItem && typeof currentStyleItem.close === "function")
            currentStyleItem.close();

    }

    onActiveBarStyleChanged: {
        if (activeBarStyle === "minflair")
            loadMinflair = true;
        else if (activeBarStyle === "island")
            loadIsland = true;
        else if (activeBarStyle === "notch")
            loadNotch = true;
        else if (activeBarStyle === "convex")
            loadConvex = true;
    }
    implicitWidth: currentStyleItem && currentStyleItem.implicitWidth > 0 ? currentStyleItem.implicitWidth : (BarStyleConfig.isPill(activeBarStyle) ? 180 : 0)

    Loader {
        id: minflairLoader

        anchors.fill: parent
        active: mainBar.loadMinflair
        visible: mainBar.activeBarStyle === "minflair" || (mainBar.activeBarStyle === "" && SettingsService.barStyle === "minflair")
        sourceComponent: minflairComp
        enabled: visible
    }

    Loader {
        id: islandLoader

        anchors.fill: parent
        active: mainBar.loadIsland
        visible: mainBar.activeBarStyle === "island"
        sourceComponent: islandComp
        enabled: visible
    }

    Loader {
        id: notchLoader

        anchors.fill: parent
        active: mainBar.loadNotch
        visible: mainBar.activeBarStyle === "notch"
        sourceComponent: notchComp
        enabled: visible
    }

    Loader {
        id: convexLoader

        anchors.fill: parent
        active: mainBar.loadConvex
        visible: mainBar.activeBarStyle === "convex"
        sourceComponent: convexComp
        enabled: visible
    }

    Component {
        id: minflairComp

        MinflairBar {
            notificationService: mainBar.notificationService
            mainPanelWidget: mainBar.mainPanelWidget
        }

    }

    Component {
        id: islandComp

        IslandBar {
            notificationService: mainBar.notificationService
            mainPanelWidget: mainBar.mainPanelWidget
        }

    }

    Component {
        id: notchComp

        NotchBar {
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
