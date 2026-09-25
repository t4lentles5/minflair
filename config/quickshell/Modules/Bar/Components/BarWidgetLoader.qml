import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Services
import qs.Modules.Bar // For BarStyleConfig
import qs.Modules.Bar.Components

Item {
    id: root

    property string widgetType: "none"
    property QtObject mainBar: null
    property bool isExpanded: mainBar && mainBar.isExpanded !== undefined ? mainBar.isExpanded : false
    property bool isCenterSlot: false
    property bool islandOrNotchOnly: false
    property bool animateTransitions: true
    // Instead of passing isIsland/isNotch flags, use a generic 'visibleInSlot' logic based on the mainBar contract.
    readonly property bool shouldShow: {
        if (widgetType === "none")
            return false;

        if (widgetType === "recording")
            return RecorderService.running;

        if (widgetType === "media") {
            let p = MprisService.activePlayer;
            let hasMedia = p !== null && (((p.trackTitle || "").trim() !== "") || ((p.trackArtist || "").trim() !== ""));
            if (!hasMedia)
                return false;

        }
        // If it's a center slot, it should show its widget unless constrained
        if (isCenterSlot)
            return true;

        if (islandOrNotchOnly) {
            // "islandOrNotchOnly" usually meant it should only show if we are in a compact, expandable style (like island/notch)
            // If the bar style is not expandable (e.g. Minflair/Framed), return false
            if (mainBar && mainBar.activeBarStyle && !BarStyleConfig.isExpandable(mainBar.activeBarStyle))
                return false;

            return isExpanded;
        }
        // If we are in an expandable bar (Island/Notch), and not islandOrNotchOnly, maybe we only show when expanded?
        if (mainBar && mainBar.activeBarStyle && BarStyleConfig.isExpandable(mainBar.activeBarStyle))
            return isExpanded;

        // Standard minflair/framed bar behavior
        return true;
    }
    readonly property real targetWidth: loader.item ? (loader.item.implicitWidth > 0 ? loader.item.implicitWidth : (loader.item.Layout && loader.item.Layout.preferredWidth !== undefined ? loader.item.Layout.preferredWidth : 0)) : 0

    implicitWidth: shouldShow ? targetWidth : 0
    implicitHeight: SettingsService.barWidgetHeight
    width: Layout.preferredWidth >= 0 ? Layout.preferredWidth : implicitWidth
    height: Layout.preferredHeight >= 0 ? Layout.preferredHeight : implicitHeight
    visible: (opacity > 0.001) && (Layout.preferredWidth > 0.5)
    clip: state !== "visible"
    Layout.alignment: Qt.AlignVCenter
    Layout.preferredHeight: SettingsService.barWidgetHeight
    state: (shouldShow && targetWidth > 0.5) ? "visible" : "hidden"
    states: [
        State {
            name: "visible"

            PropertyChanges {
                target: root
                Layout.preferredWidth: root.targetWidth
                opacity: 1
            }

        },
        State {
            name: "hidden"

            PropertyChanges {
                target: root
                Layout.preferredWidth: 0
                opacity: 0
            }

        }
    ]
    transitions: [
        Transition {
            NumberAnimation {
                properties: "Layout.preferredWidth,opacity"
                duration: root.animateTransitions ? Constants.animNormal : 0
                easing.type: Easing.OutCubic
            }

        }
    ]

    Loader {
        id: loader

        anchors.centerIn: parent
        active: widgetType !== "none"
        sourceComponent: {
            switch (widgetType) {
            case "workspaces":
                return wsComp;
            case "media":
                return mediaComp;
            case "clock":
                return clockComp;
            case "tray":
                return trayComp;
            case "control_center":
                return ccComp;
            case "recording":
                return recComp;
            default:
                return undefined;
            }
        }
    }

    Component {
        id: wsComp

        Workspaces {
            // Generic logic instead of isIsland || isNotch
            property bool isCompactStyle: (root.mainBar && root.mainBar.activeBarStyle ? BarStyleConfig.isCompact(root.mainBar.activeBarStyle) : false) || SettingsService.isBarCompact

            compact: isCompactStyle
            height: SettingsService.isBarCompact ? 24 : (isCompactStyle ? 28 : implicitHeight)
        }

    }

    Component {
        id: mediaComp

        MediaButton {
            height: root.height
        }

    }

    Component {
        id: clockComp

        ClockButton {
        }

    }

    Component {
        id: trayComp

        SystemTrayGroup {
            forceHide: !root.shouldShow
        }

    }

    Component {
        id: ccComp

        ControlCenterButton {
            property bool isCompactStyle: (root.mainBar && root.mainBar.activeBarStyle ? BarStyleConfig.isCompact(root.mainBar.activeBarStyle) : false) || SettingsService.isBarCompact

            notificationService: root.mainBar ? root.mainBar.notificationService : null
            horizontalPadding: isCompactStyle ? (SettingsService.isBarCompact ? Constants.sizeXs : 10) : Constants.sizeLg
        }

    }

    Component {
        id: recComp

        RecordingIndicator {
        }

    }

}
