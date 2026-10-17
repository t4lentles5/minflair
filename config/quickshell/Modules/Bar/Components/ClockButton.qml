import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services

Rectangle {
    id: root

    property bool isHovered: mouseArea.containsMouse
    property bool isPressed: mouseArea.pressed

    color: "transparent"
    implicitWidth: mainLayout.implicitWidth
    implicitHeight: mainLayout.implicitHeight
    width: implicitWidth
    height: implicitHeight
    scale: DisplayProfileService.gameModeActive ? 1 : (isPressed ? 0.95 : (isHovered ? 1.02 : 1))

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton
        onClicked: AppState.toggleWidget("calendar")
    }

    Behavior on scale {
        NumberAnimation {
            duration: Constants.animFast
            easing.type: Easing.OutBack
        }

    }

    RowLayout {
        id: mainLayout

        anchors.centerIn: parent
        spacing: 0

        ThemedText {
            id: baseTimeText

            text: {
                const t = SystemInfoService.currentTime;
                if (SettingsService.clock24h)
                    return Qt.formatDateTime(t, "HH:mm");

                const h = t.getHours() % 12 || 12;
                const m = t.getMinutes().toString().padStart(2, "0");
                return h + ":" + m;
            }
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

            text: " " + (SystemInfoService.currentTime.getHours() >= 12 ? "PM" : "AM")
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
