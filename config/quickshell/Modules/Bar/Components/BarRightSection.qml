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

        BarWidgetLoader {
            id: slotR2

            widgetType: SettingsService.barSlotR2
            mainBar: root.mainBar
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
