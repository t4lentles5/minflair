import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Core
import qs.Core.Services

Item {
    id: root

    property bool hasFullscreen: false
    property int barHeight: 40
    property int bezelSize: 8
    property bool isExiting: false
    readonly property bool isExclusionActive: SettingsService.barConvexMode && !root.hasFullscreen && !root.isExiting

    PanelWindow {
        id: bottomExclusion

        anchors.bottom: true
        anchors.left: true
        anchors.right: true
        WlrLayershell.layer: WlrLayer.Bottom
        color: "transparent"
        focusable: false
        WlrLayershell.exclusiveZone: root.isExclusionActive ? root.bezelSize : 0
        implicitHeight: root.isExclusionActive ? root.bezelSize : 0
        visible: root.isExclusionActive

        mask: Region {
        }

    }

    PanelWindow {
        id: leftExclusion

        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        WlrLayershell.layer: WlrLayer.Bottom
        color: "transparent"
        focusable: false
        WlrLayershell.exclusiveZone: root.isExclusionActive ? root.bezelSize : 0
        implicitWidth: root.isExclusionActive ? root.bezelSize : 0
        visible: root.isExclusionActive

        mask: Region {
        }

    }

    PanelWindow {
        id: rightExclusion

        anchors.top: true
        anchors.bottom: true
        anchors.right: true
        WlrLayershell.layer: WlrLayer.Bottom
        color: "transparent"
        focusable: false
        WlrLayershell.exclusiveZone: root.isExclusionActive ? root.bezelSize : 0
        implicitWidth: root.isExclusionActive ? root.bezelSize : 0
        visible: root.isExclusionActive

        mask: Region {
        }

    }

}
