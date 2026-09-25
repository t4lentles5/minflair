import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Bar
import qs.Modules.Bar.Widgets.SystemTray as STray

Rectangle {
    id: root

    property bool forceHide: false
    readonly property bool shouldShow: !forceHide && trayRow.implicitWidth > 0
    readonly property real targetWidth: Math.min(trayRow.implicitWidth + (SettingsService.isBarCompact ? Constants.sizeXs : Constants.sizeSm * 2), Layout.maximumWidth)

    implicitHeight: SettingsService.barWidgetHeight
    implicitWidth: shouldShow ? targetWidth : 0
    width: implicitWidth
    height: implicitHeight
    Layout.preferredHeight: SettingsService.barWidgetHeight
    Layout.alignment: Qt.AlignVCenter
    Layout.maximumWidth: 150 + Constants.sizeSm * 2
    Layout.preferredWidth: implicitWidth
    opacity: shouldShow ? 1 : 0
    visible: opacity > 0.001 && implicitWidth > 0.5
    clip: true
    color: SettingsService.isBarCompact ? "transparent" : Theme.bgSecondary
    radius: height / 2

    Flickable {
        id: trayFlick

        anchors.fill: parent
        anchors.leftMargin: SettingsService.isBarCompact ? Constants.size2Xs : Constants.sizeSm
        anchors.rightMargin: SettingsService.isBarCompact ? Constants.size2Xs : Constants.sizeSm
        contentWidth: trayRow.implicitWidth
        contentHeight: height
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.HorizontalFlick
        clip: true

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            onWheel: (wheel) => {
                trayFlick.contentX = Math.max(0, Math.min(trayFlick.contentX - (wheel.angleDelta.y / 2), trayFlick.contentWidth - trayFlick.width));
            }
        }

        RowLayout {
            id: trayRow

            height: parent.height
            spacing: Constants.sizeSm

            Repeater {
                model: SystemTray.items

                delegate: STray.TrayItem {
                    trayItem: modelData
                    iconSize: (SettingsService.isBarCompact || BarStyleConfig.isCompact(SettingsService.barStyle)) ? Constants.sizeSm : Constants.sizeMd
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.RightButton) {
                            if (modelData.menu)
                                AppState.togglePopup("systemTray_" + index);
                            else if (modelData.secondaryActivate)
                                modelData.secondaryActivate();
                        }
                    }
                }

            }

        }

    }

    Behavior on Layout.preferredWidth {
        NumberAnimation {
            duration: Constants.animNormal
            easing.type: Easing.OutCubic
        }

    }

    Behavior on opacity {
        NumberAnimation {
            duration: Constants.animNormal
            easing.type: Easing.OutCubic
        }

    }

}
