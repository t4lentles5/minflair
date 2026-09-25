import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Bar
import qs.Modules.Bar.Components

Rectangle {
    id: root

    property var mainPanelWidget: null
    property var notificationService: null
    property QtObject mainBar: null
    property real sidePadding: 32
    property real contentMargin: Constants.sizeLg

    height: parent ? parent.height : implicitHeight
    width: contentRow.implicitWidth + root.sidePadding
    color: "transparent"

    RowLayout {
        id: contentRow

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: root.contentMargin
        spacing: Constants.sizeXs

        BarWidgetLoader {
            id: slotR1

            widgetType: SettingsService.barSlotR1
            mainBar: root.mainBar
        }

        Divider {
            id: divR1R2

            vertical: true
            visible: SettingsService.isBarCompact && slotR1.shouldShow && (slotR2.shouldShow || slotR3.shouldShow)
            opacity: visible ? 1 : 0
            Layout.fillHeight: false
            Layout.preferredHeight: 14
            Layout.preferredWidth: visible ? 1 : 0
            Layout.alignment: Qt.AlignVCenter
        }

        BarWidgetLoader {
            id: slotR2

            widgetType: SettingsService.barSlotR2
            mainBar: root.mainBar
        }

        Divider {
            id: divR2R3

            vertical: true
            visible: SettingsService.isBarCompact && (slotR1.shouldShow || slotR2.shouldShow) && slotR3.shouldShow
            opacity: visible ? 1 : 0
            Layout.fillHeight: false
            Layout.preferredHeight: 14
            Layout.preferredWidth: visible ? 1 : 0
            Layout.alignment: Qt.AlignVCenter
        }

        BarWidgetLoader {
            id: slotR3

            widgetType: SettingsService.barSlotR3
            mainBar: root.mainBar
        }

        PowerButton {
            id: powerBtn

            popupId: "powerMenu"
            Layout.alignment: Qt.AlignVCenter
        }

    }

}
