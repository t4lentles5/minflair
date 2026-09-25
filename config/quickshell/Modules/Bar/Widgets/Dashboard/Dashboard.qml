import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Core
import qs.Core.Services
import qs.Core.Windows

Item {
    id: root

    property string popupId: "dashboard"
    property bool isOpen: false
    property int popupStartY: SettingsService.barFramedMode ? 48 : 56
    readonly property bool isConvex: SettingsService.barConvexMode
    readonly property bool _visible: contentLoader.item ? contentLoader.item._visible : false

    signal popupOpened()
    signal popupClosed()
    signal fullyClosed()

    onIsOpenChanged: {
        if (contentLoader.item && contentLoader.item.isOpen !== root.isOpen)
            contentLoader.item.isOpen = root.isOpen;

    }

    Loader {
        id: contentLoader

        anchors.fill: parent
        sourceComponent: root.isConvex ? sidebarComponent : topPopupComponent
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

        function onPopupOpened() {
            root.popupOpened();
        }

        function onPopupClosed() {
            root.popupClosed();
        }

        function onFullyClosed() {
            root.fullyClosed();
        }

        target: contentLoader.item
        ignoreUnknownSignals: true
    }

    // TopPopup for minflair and framed modes (top and center, horizontal)
    Component {
        id: topPopupComponent

        TopPopup {
            id: topPopup

            popupId: "dashboard"
            animateHeight: true
            contentPadding: Constants.sizeLg
            backgroundColor: Theme.bg
            x: Math.round((root.width - implicitWidth) / 2)
            y: root.popupStartY

            Flickable {
                id: topFlickable

                implicitWidth: topContent.implicitWidth
                implicitHeight: Math.min(topContent.implicitHeight, root.height > 0 ? root.height - 120 : 700)
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: width
                contentHeight: topContent.implicitHeight
                clip: true
                interactive: contentHeight > height
                boundsBehavior: Flickable.StopAtBounds

                DashboardContent {
                    id: topContent

                    width: topFlickable.width
                    widget: topPopup
                    isVertical: false
                }

                ScrollIndicator.vertical: ScrollIndicator {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    visible: topFlickable.contentHeight > topFlickable.height
                }

            }

        }

    }

    // SidebarWindow for convex mode (left side, vertical)
    Component {
        id: sidebarComponent

        SidebarWindow {
            id: sidebarWindow

            popupId: "dashboard"
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

}
