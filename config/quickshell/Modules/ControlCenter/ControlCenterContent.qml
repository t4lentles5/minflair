import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Modules.ControlCenter.Widgets.PerformanceWidget
import qs.Modules.ControlCenter.Widgets.QuickSettings

GridLayout {
    id: root

    property var widget: null
    property var notificationService: null
    readonly property bool isPopupOpen: widget ? (widget.isOpen !== undefined ? widget.isOpen : true) : true

    columns: 1
    rows: 2
    rowSpacing: Constants.sizeLg
    implicitWidth: Math.max(520, quickSettings.implicitWidth)
    implicitHeight: quickSettings.implicitHeight + (performanceWidget.visible ? performanceWidget.implicitHeight + rowSpacing : 0)
    Layout.fillWidth: true
    Layout.fillHeight: true

    QuickSettings {
        id: quickSettings

        Layout.row: 0
        Layout.column: 0
        Layout.fillWidth: true
        quickSettingsOpen: root.isPopupOpen
        notificationService: root.notificationService
    }

    PerformanceWidget {
        id: performanceWidget

        Layout.row: 1
        Layout.column: 0
        Layout.fillWidth: true
        visible: quickSettings.activePageIndex === 0
    }

}
