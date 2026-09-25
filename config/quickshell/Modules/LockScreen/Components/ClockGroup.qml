import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services

ColumnLayout {
    spacing: Constants.sizeLg

    RowLayout {
        spacing: Constants.sizeSm

        ThemedText {
            text: Qt.formatTime(SystemInfoService.currentTime, "hh")
            customSize: Constants.size5Xl * 4
            font.weight: Font.Light
        }

        Column {
            Layout.alignment: Qt.AlignVCenter
            spacing: Constants.size5Xl * 0.7

            Rectangle {
                width: Constants.sizeMd
                height: Constants.sizeMd
                radius: Constants.sizeMd / 2
                color: Theme.accent
            }

            Rectangle {
                width: Constants.sizeMd
                height: Constants.sizeMd
                radius: Constants.sizeMd / 2
                color: Theme.accent
            }

        }

        ThemedText {
            text: Qt.formatTime(SystemInfoService.currentTime, "mm")
            customSize: Constants.size5Xl * 4
            font.weight: Font.Light
        }

    }

    ThemedText {
        text: Qt.formatDate(SystemInfoService.currentTime, "ddd . dd MMM / yyyy").toUpperCase()
        customSize: Constants.sizeMd
        font.letterSpacing: 4
        color: Theme.muted
        font.bold: true
    }

}
