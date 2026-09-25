import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services

Rectangle {
    id: root

    color: "transparent"
    implicitWidth: mainLayout.implicitWidth
    implicitHeight: mainLayout.implicitHeight
    width: implicitWidth
    height: implicitHeight

    RowLayout {
        id: mainLayout

        anchors.centerIn: parent
        spacing: 0

        ThemedText {
            id: baseTimeText

            text: SettingsService.clock24h ? Qt.formatDateTime(SystemInfoService.currentTime, "HH:mm") : Qt.formatDateTime(SystemInfoService.currentTime, "h:mm AP").replace(" AM", "").replace(" PM", "")
            font.bold: true
        }

        ThemedText {
            id: secondsText

            text: Qt.formatDateTime(SystemInfoService.currentTime, ":ss")
            font.bold: true
            opacity: SettingsService.clockSeconds ? 1 : 0
            Layout.preferredWidth: SettingsService.clockSeconds ? implicitWidth : 0
            clip: true

            Behavior on Layout.preferredWidth {
                NumberAnimation {
                    duration: Constants.animNormal
                    easing.type: Easing.OutQuint
                }

            }

            Behavior on opacity {
                NumberAnimation {
                    duration: Constants.animNormal
                }

            }

        }

        ThemedText {
            id: apText

            text: Qt.formatDateTime(SystemInfoService.currentTime, " AP")
            font.bold: true
            visible: !SettingsService.clock24h
        }

        Item {
            Layout.preferredWidth: SettingsService.clockShowDate ? Constants.sizeXs : 0

            Behavior on Layout.preferredWidth {
                NumberAnimation {
                    duration: Constants.animNormal
                    easing.type: Easing.OutQuint
                }

            }

        }

        ThemedText {
            text: ""
            opacity: SettingsService.clockShowDate ? 1 : 0
            Layout.preferredWidth: SettingsService.clockShowDate ? implicitWidth : 0
            clip: true
            customSize: Constants.sizeXs - 2

            Behavior on Layout.preferredWidth {
                NumberAnimation {
                    duration: Constants.animNormal
                    easing.type: Easing.OutQuint
                }

            }

            Behavior on opacity {
                NumberAnimation {
                    duration: Constants.animNormal
                }

            }

        }

        Item {
            Layout.preferredWidth: SettingsService.clockShowDate ? Constants.sizeXs : 0

            Behavior on Layout.preferredWidth {
                NumberAnimation {
                    duration: Constants.animNormal
                    easing.type: Easing.OutQuint
                }

            }

        }

        ThemedText {
            id: dateText

            text: Qt.formatDateTime(SystemInfoService.currentTime, "ddd, d MMM")
            color: Theme.muted
            opacity: SettingsService.clockShowDate ? 1 : 0
            Layout.preferredWidth: SettingsService.clockShowDate ? implicitWidth : 0
            clip: true

            Behavior on Layout.preferredWidth {
                NumberAnimation {
                    duration: Constants.animNormal
                    easing.type: Easing.OutQuint
                }

            }

            Behavior on opacity {
                NumberAnimation {
                    duration: Constants.animNormal
                }

            }

        }

    }

}
