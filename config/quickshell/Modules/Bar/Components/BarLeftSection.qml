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

        BarWidgetLoader {
            id: slotL2

            widgetType: SettingsService.barSlotL2
            mainBar: root.mainBar
        }

        BarWidgetLoader {
            id: slotL3

            widgetType: SettingsService.barSlotL3
            mainBar: root.mainBar
        }

    }

}
