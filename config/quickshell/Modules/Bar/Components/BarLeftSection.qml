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

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: root.contentMargin
        spacing: Constants.sizeXs

        MinflairButton {
            id: minflairBtn

            widget: root.mainPanelWidget
            Layout.alignment: Qt.AlignVCenter
        }

        BarWidgetLoader {
            id: slotL1

            widgetType: SettingsService.barSlotL1
            mainBar: root.mainBar
        }

        Divider {
            id: divL1L2

            vertical: true
            visible: SettingsService.isBarCompact && slotL1.shouldShow && (slotL2.shouldShow || slotL3.shouldShow)
            opacity: visible ? 1 : 0
            Layout.fillHeight: false
            Layout.preferredHeight: 14
            Layout.preferredWidth: visible ? 1 : 0
            Layout.alignment: Qt.AlignVCenter
        }

        BarWidgetLoader {
            id: slotL2

            widgetType: SettingsService.barSlotL2
            mainBar: root.mainBar
        }

        Divider {
            id: divL2L3

            vertical: true
            visible: SettingsService.isBarCompact && (slotL1.shouldShow || slotL2.shouldShow) && slotL3.shouldShow
            opacity: visible ? 1 : 0
            Layout.fillHeight: false
            Layout.preferredHeight: 14
            Layout.preferredWidth: visible ? 1 : 0
            Layout.alignment: Qt.AlignVCenter
        }

        BarWidgetLoader {
            id: slotL3

            widgetType: SettingsService.barSlotL3
            mainBar: root.mainBar
        }

    }

}
