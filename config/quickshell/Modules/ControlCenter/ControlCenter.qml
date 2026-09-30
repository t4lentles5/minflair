import QtQuick
import qs.Core
import qs.Core.Services
import qs.Core.Windows

Item {
    id: root

    property var notificationService: null
    property int popupStartY: 0
    property bool isOpen: false

    signal fullyClosed()

    onIsOpenChanged: {
        if (internalLoader.item)
            internalLoader.item.isOpen = root.isOpen;

    }

    Loader {
        id: internalLoader

        anchors.fill: parent
        sourceComponent: SettingsService.barMinflairMode ? topPopupComponent : sidebarComponent
        onLoaded: {
            if (item)
                item.isOpen = root.isOpen;

        }

        Connections {
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
            popupId: "controlCenter"
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

    Component {
        id: topPopupComponent

        Item {
            id: topItem

            property bool isOpen: false

            signal fullyClosed()

            TopPopup {
                id: thePopup

                popupId: "controlCenter"
                isOpen: topItem.isOpen
                positionAtRight: false
                animateHeight: true
                contentPadding: Constants.sizeLg
                backgroundColor: Theme.bg
                contentWidth: contentTop.implicitWidth
                contentHeight: contentTop.implicitHeight
                // Position exactly on the right, like SystemTray
                x: root.width - implicitWidth - 8
                y: root.popupStartY

                ControlCenterContent {
                    id: contentTop

                    widget: thePopup
                    notificationService: root.notificationService
                }

                Connections {
                    function onFullyClosed() {
                        topItem.fullyClosed();
                    }

                    target: thePopup
                }

            }

        }

    }

}
