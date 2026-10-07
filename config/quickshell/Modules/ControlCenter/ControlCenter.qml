import QtQuick
import qs.Core
import qs.Core.Services
import qs.Core.Windows

Item {
    id: root

    property var notificationService: null
    property bool isOpen: false
    readonly property bool _visible: internalLoader.item ? internalLoader.item._visible : false

    signal widgetOpened()
    signal widgetClosed()
    signal fullyClosed()

    onIsOpenChanged: {
        if (internalLoader.item && internalLoader.item.isOpen !== root.isOpen)
            internalLoader.item.isOpen = root.isOpen;

    }

    Loader {
        id: internalLoader

        anchors.fill: parent
        sourceComponent: sidebarComponent
        onStatusChanged: {
            if (status === Loader.Ready && item)
                item.isOpen = root.isOpen;

        }

        Connections {
            function onIsOpenChanged() {
                if (internalLoader.item && root.isOpen !== internalLoader.item.isOpen)
                    root.isOpen = internalLoader.item.isOpen;

            }

            function onFullyClosed() {
                root.fullyClosed();
            }

            target: internalLoader.item
            ignoreUnknownSignals: true
        }

    }

    Component {
        id: sidebarComponent

        SidebarWindow {
            widgetId: "controlCenter"
            isOpen: root.isOpen
            anchors.fill: parent
            preferredHeight: 0
            backgroundColor: Theme.bg
            preferredWidth: content.implicitWidth + (Constants.sizeLg * 2)

            ControlCenterContent {
                id: content

                widget: parent
                notificationService: root.notificationService
            }

        }

    }

    Binding on isOpen {
        value: AppState.isWidgetOpen("controlCenter")
    }

}
