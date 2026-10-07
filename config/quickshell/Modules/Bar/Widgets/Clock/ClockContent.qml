import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services

Item {
    id: root

    property var widget: null
    property date now: new Date()

    implicitWidth: 300
    implicitHeight: 95
    width: implicitWidth
    height: implicitHeight

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Constants.size2Xs
        spacing: Constants.sizeXs

        // Header: Big Time & Format Controls
        RowLayout {
            Layout.fillWidth: true
            spacing: Constants.sizeSm

            ThemedText {
                text: {
                    if (SettingsService.clock24h)
                        return Qt.formatDateTime(root.now, "HH:mm");

                    let h = root.now.getHours() % 12 || 12;
                    let m = root.now.getMinutes().toString().padStart(2, "0");
                    return h + ":" + m;
                }
                font.bold: true
                customSize: Constants.size4Xl - 4
                color: Theme.fg
            }

            ColumnLayout {
                spacing: Constants.size3Xs
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                    visible: !SettingsService.clock24h
                    color: Theme.bgSecondary
                    radius: Constants.sizeXs - 2
                    Layout.preferredWidth: apText.implicitWidth + 10
                    Layout.preferredHeight: Constants.sizeLg + 2

                    ThemedText {
                        id: apText

                        anchors.centerIn: parent
                        text: root.now.getHours() >= 12 ? "PM" : "AM"
                        font.bold: true
                        customSize: Constants.sizeXs - 2
                        color: Theme.accent
                    }

                }

                ThemedText {
                    text: Qt.formatDateTime(root.now, ":ss")
                    customSize: Constants.sizeMd
                    font.bold: true
                    color: Theme.muted
                }

            }

            Item {
                Layout.fillWidth: true
            }

            // Dynamic Day / Night Large Icon
            SvgIcon {
                readonly property int currentHour: root.now.getHours()
                readonly property bool isDay: currentHour >= 6 && currentHour < 18

                Layout.alignment: Qt.AlignVCenter
                Layout.rightMargin: Constants.size2Xs
                icon: isDay ? "sun" : "moon-filled"
                iconSize: 38
                iconColor: Theme.accent
                flat: true
            }

        }

        // Subtitle: Date & Day
        RowLayout {
            Layout.fillWidth: true
            spacing: Constants.sizeXs

            SvgIcon {
                icon: "calendar"
                iconSize: 15
                iconColor: Theme.accent
                flat: true
            }

            ThemedText {
                text: Qt.formatDateTime(root.now, "dddd, MMMM d")
                customSize: Constants.sizeSm
                color: Theme.muted
                font.bold: true
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

        }

    }

}
