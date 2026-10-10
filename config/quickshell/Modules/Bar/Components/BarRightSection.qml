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
    property var controlCenterWidget: null
    property var notificationsCenterWidget: null
    property var notificationService: null
    property QtObject mainBar: null
    property real sidePadding: Constants.size3Xl
    property real contentMargin: Constants.sizeLg
    readonly property real targetWidth: contentRow.implicitWidth + root.sidePadding

    height: parent ? parent.height : implicitHeight
    width: targetWidth
    color: "transparent"

    RowLayout {
        id: contentRow

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: root.contentMargin
        spacing: Constants.sizeXs

        RecordingIndicator {
            id: recIndicator

            Layout.alignment: Qt.AlignVCenter
            visible: RecorderService.running
        }

        Rectangle {
            id: statusCapsule

            readonly property real sidePadding: Constants.size3Xs

            implicitHeight: SettingsService.barWidgetHeight
            implicitWidth: capsuleRow.implicitWidth + sidePadding * 2
            width: implicitWidth
            height: implicitHeight
            Layout.preferredHeight: implicitHeight
            Layout.preferredWidth: implicitWidth
            Layout.alignment: Qt.AlignVCenter
            color: Theme.bgSecondary
            radius: DisplayProfileService.gameModeActive ? 0 : height / 2

            RowLayout {
                id: capsuleRow

                anchors.centerIn: parent
                spacing: Constants.size3Xs

                ControlCenterButton {
                    id: ccBtn

                    notificationService: root.notificationService
                    controlCenterWidget: root.controlCenterWidget
                    Layout.alignment: Qt.AlignVCenter
                }

                NotificationsButton {
                    id: notifBtn

                    notificationService: root.notificationService
                    notificationsCenterWidget: root.notificationsCenterWidget
                    Layout.alignment: Qt.AlignVCenter
                }

                SystemTrayGroup {
                    id: trayGroup

                    forceHide: false
                    hasBackground: false
                    Layout.alignment: Qt.AlignVCenter
                    visible: shouldShow
                }

            }

            Behavior on Layout.preferredWidth {
                NumberAnimation {
                    duration: Constants.animNormal
                    easing.type: Easing.OutCubic
                }

            }

        }

        PowerButton {
            id: powerBtn

            widgetId: "powerMenu"
            Layout.alignment: Qt.AlignVCenter
        }

    }

}
