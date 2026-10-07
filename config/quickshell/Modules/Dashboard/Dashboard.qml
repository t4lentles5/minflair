import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Core
import qs.Core.Services
import qs.Core.Windows

Item {
    id: root

    property string widgetId: "dashboard"
    property bool isOpen: false
    readonly property bool _visible: contentLoader.item ? contentLoader.item._visible : false

    signal widgetOpened()
    signal widgetClosed()
    signal fullyClosed()

    onIsOpenChanged: {
        if (contentLoader.item && contentLoader.item.isOpen !== root.isOpen)
            contentLoader.item.isOpen = root.isOpen;

    }

    Loader {
        id: contentLoader

        anchors.fill: parent
        sourceComponent: sidebarComponent
        onStatusChanged: {
            if (status === Loader.Ready && item)
                item.isOpen = root.isOpen;

        }
    }

    Connections {
        function onIsOpenChanged() {
            if (contentLoader.item && root.isOpen !== contentLoader.item.isOpen)
                root.isOpen = contentLoader.item.isOpen;

        }

        function onWidgetOpened() {
            root.widgetOpened();
        }

        function onWidgetClosed() {
            root.widgetClosed();
        }

        function onFullyClosed() {
            root.fullyClosed();
        }

        target: contentLoader.item
        ignoreUnknownSignals: true
    }

    // SidebarWindow for convex mode (left side, vertical)
    Component {
        id: sidebarComponent

        SidebarWindow {
            id: sidebarWindow

            widgetId: root.widgetId
            isOpen: root.isOpen
            anchors.fill: parent
            positionAtLeft: true
            backgroundColor: Theme.bg
            preferredWidth: sideContent.implicitWidth + (Constants.sizeLg * 2) + 8
            contentHeight: sideContent.implicitHeight

            Flickable {
                id: sideFlickable

                Layout.fillWidth: true
                Layout.fillHeight: true
                implicitWidth: sideContent.implicitWidth
                implicitHeight: sideContent.implicitHeight
                contentWidth: width
                contentHeight: sideContent.implicitHeight
                clip: true
                interactive: contentHeight > height
                boundsBehavior: Flickable.StopAtBounds

                DashboardContent {
                    id: sideContent

                    width: sideFlickable.width
                    widget: sidebarWindow
                    isVertical: true
                }

                ScrollIndicator.vertical: ScrollIndicator {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    visible: sideFlickable.contentHeight > sideFlickable.height
                }

            }

        }

    }

    Binding on isOpen {
        value: AppState.isWidgetOpen(root.widgetId)
    }

}
