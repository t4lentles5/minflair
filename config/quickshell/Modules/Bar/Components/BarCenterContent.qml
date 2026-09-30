import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Bar
import qs.Modules.Bar.Components

RowLayout {
    id: root

    property QtObject mainBar: null
    property bool animateTransitions: true
    property var notificationService: null
    property var widget: null
    readonly property bool isExpandable: mainBar && mainBar.activeBarStyle ? BarStyleConfig.isExpandable(mainBar.activeBarStyle) : false
    readonly property bool isExpanded: mainBar ? mainBar.isExpanded : false

    spacing: 6

    MinflairButton {
        widget: root.widget
        enableIntervalAnim: root.animateTransitions
        Layout.alignment: Qt.AlignVCenter
        customClickHandler: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                // In an expandable bar, right click toggles expansion
                if (root.mainBar && root.mainBar.activeBarStyle === "island")
                    SettingsService.barIslandExpanded = !SettingsService.barIslandExpanded;
                else if (root.mainBar && root.mainBar.activeBarStyle === "notch")
                    SettingsService.barNotchExpanded = !SettingsService.barNotchExpanded;
            } else {
                AppState.togglePopup("dashboard");
            }
        }
    }

    BarWidgetLoader {
        widgetType: SettingsService.barSlotL1
        mainBar: root.mainBar
        islandOrNotchOnly: true
        animateTransitions: root.animateTransitions
    }

    BarWidgetLoader {
        widgetType: SettingsService.barSlotL2
        mainBar: root.mainBar
        islandOrNotchOnly: true
        animateTransitions: root.animateTransitions
    }

    BarWidgetLoader {
        widgetType: SettingsService.barSlotL3
        mainBar: root.mainBar
        islandOrNotchOnly: true
        animateTransitions: root.animateTransitions
    }

    BarCenterSection {
        mainBar: root.mainBar
        animateTransitions: root.animateTransitions
    }

    BarWidgetLoader {
        widgetType: SettingsService.barSlotR1
        mainBar: root.mainBar
        islandOrNotchOnly: true
        animateTransitions: root.animateTransitions
    }

    BarWidgetLoader {
        widgetType: SettingsService.barSlotR2
        mainBar: root.mainBar
        islandOrNotchOnly: true
        animateTransitions: root.animateTransitions
    }

    BarWidgetLoader {
        widgetType: SettingsService.barSlotR3
        mainBar: root.mainBar
        islandOrNotchOnly: true
        animateTransitions: root.animateTransitions
    }

    Item {
        id: powerContainer

        visible: opacity > 0.001
        clip: true
        Layout.alignment: Qt.AlignVCenter
        Layout.preferredHeight: SettingsService.barWidgetHeight
        Layout.preferredWidth: !root.isExpandable || root.isExpanded ? powerBtn.implicitWidth : 0
        opacity: !root.isExpandable || root.isExpanded ? 1 : 0

        PowerButton {
            id: powerBtn

            popupId: "powerMenu"
            anchors.centerIn: parent
        }

        Behavior on Layout.preferredWidth {
            NumberAnimation {
                duration: Constants.animSlow
                easing.type: Easing.OutQuint
            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: Constants.animNormal
                easing.type: Easing.OutCubic
            }

        }

    }

}
