import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Bar.Components

Item {
    id: root

    property bool clickable: true

    implicitWidth: clockRow.implicitWidth
    implicitHeight: clockRow.implicitHeight
    width: implicitWidth
    height: implicitHeight

    RowLayout {
        id: clockRow

        anchors.centerIn: parent
        spacing: RecorderService.running ? 8 : 0

        Item {
            id: clockBox

            implicitWidth: clockDateLayout.implicitWidth
            implicitHeight: clockDateLayout.implicitHeight
            width: implicitWidth
            height: implicitHeight
            Layout.preferredWidth: implicitWidth
            Layout.preferredHeight: implicitHeight
            Layout.alignment: Qt.AlignVCenter

            RowLayout {
                id: clockDateLayout

                anchors.fill: parent
                spacing: Constants.size2Xs

                ThemedText {
                    id: baseTimeText

                    text: {
                        let t = SystemInfoService.currentTime;
                        if (SettingsService.clock24h)
                            return Qt.formatDateTime(t, "HH:mm");

                        let h = t.getHours() % 12 || 12;
                        let m = t.getMinutes().toString().padStart(2, "0");
                        return h + ":" + m;
                    }
                    font.bold: true
                    Layout.alignment: Qt.AlignVCenter
                }

                ThemedText {
                    id: secondsText

                    text: Qt.formatDateTime(SystemInfoService.currentTime, ":ss")
                    font.bold: true
                    color: Theme.muted
                    visible: SettingsService.clockSeconds
                    Layout.alignment: Qt.AlignVCenter
                }

                ThemedText {
                    id: apText

                    text: SystemInfoService.currentTime.getHours() >= 12 ? "PM" : "AM"
                    font.bold: true
                    color: Theme.accent
                    visible: !SettingsService.clock24h
                    Layout.alignment: Qt.AlignVCenter
                }

                ThemedText {
                    id: dateSeparator

                    text: "•"
                    customSize: Constants.sizeXs - 2
                    color: Theme.muted
                    visible: SettingsService.clockShowDate
                    Layout.alignment: Qt.AlignVCenter
                }

                ThemedText {
                    id: dateText

                    text: Qt.formatDateTime(SystemInfoService.currentTime, "ddd, d MMM")
                    color: Theme.muted
                    font.bold: true
                    visible: SettingsService.clockShowDate
                    Layout.alignment: Qt.AlignVCenter
                }

            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                enabled: root.clickable
                onClicked: AppState.toggleWidget("clock")
            }

        }

        RecordingIndicator {
            id: recIndicator

            customHeight: Constants.size2Xl
            Layout.alignment: Qt.AlignVCenter
        }

    }

}
