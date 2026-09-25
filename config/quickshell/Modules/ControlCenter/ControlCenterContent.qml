import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Modules.ControlCenter.Widgets.NotificationCenter
import qs.Modules.ControlCenter.Widgets.PerformanceWidget
import qs.Modules.ControlCenter.Widgets.QuickSettings

GridLayout {
    id: root

    property var widget: null
    property var notificationService: null
    property bool isHorizontal: SettingsService.barIslandMode || SettingsService.barNotchMode
    readonly property bool isPopupOpen: widget ? (widget.isOpen !== undefined ? widget.isOpen : true) : true

    columns: isHorizontal ? 2 : 1
    rows: isHorizontal ? 2 : 3
    rowSpacing: Constants.sizeLg
    columnSpacing: Constants.sizeLg
    implicitWidth: isHorizontal ? (Math.max(quickSettings.implicitWidth, 420) * 2 + columnSpacing) : 440
    implicitHeight: isHorizontal ? Math.max(quickSettings.implicitHeight + performanceWidget.implicitHeight + rowSpacing, 340) : 640
    Layout.fillWidth: true
    Layout.fillHeight: true

    QuickSettings {
        id: quickSettings

        Layout.row: 0
        Layout.column: 0
        Layout.rowSpan: 1
        Layout.columnSpan: 1
        Layout.fillWidth: true
        Layout.preferredWidth: root.isHorizontal ? 420 : -1
        quickSettingsOpen: root.isPopupOpen
        notificationService: root.notificationService
    }

    NotificationCenter {
        id: notificationCenter

        Layout.row: root.isHorizontal ? 0 : 1
        Layout.column: root.isHorizontal ? 1 : 0
        Layout.rowSpan: root.isHorizontal ? 2 : 1
        Layout.columnSpan: 1
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredWidth: root.isHorizontal ? 420 : -1
        notificationService: root.notificationService
        controlCenterOpen: root.isPopupOpen
    }

    PerformanceWidget {
        id: performanceWidget

        Layout.row: root.isHorizontal ? 1 : 2
        Layout.column: 0
        Layout.rowSpan: 1
        Layout.columnSpan: 1
        Layout.fillWidth: true
        Layout.preferredWidth: root.isHorizontal ? 420 : -1
    }

}
