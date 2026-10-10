import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.ControlCenter.Widgets.PerformanceWidget
import qs.Modules.ControlCenter.Widgets.QuickSettings

ColumnLayout {
    id: root

    property var widget: null
    property var notificationService: null
    readonly property bool isWidgetOpen: widget ? (widget.isOpen !== undefined ? widget.isOpen : true) : true

    function resetViews() {
        if (quickSettings && typeof quickSettings.resetView === "function")
            quickSettings.resetView();

    }

    spacing: Constants.sizeLg
    implicitWidth: Math.max(500, quickSettings.implicitWidth)
    Layout.fillWidth: true
    Layout.fillHeight: true

    Connections {
        function onFullyClosed() {
            root.resetViews();
        }

        target: root.widget
        ignoreUnknownSignals: true
    }

    QuickSettings {
        id: quickSettings

        Layout.fillWidth: true
        Layout.fillHeight: true
        quickSettingsOpen: root.isWidgetOpen
        notificationService: root.notificationService
        extraExpandedHeight: performanceWidget.implicitHeight + root.spacing
    }

    PerformanceWidget {
        id: performanceWidget

        Layout.fillWidth: true
        visible: quickSettings.activePageIndex === 0
    }

}
