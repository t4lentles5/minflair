import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Bar.Components

ColumnLayout {
    id: root

    readonly property var activePlayer: MprisService.activePlayer
    readonly property bool hasMedia: activePlayer !== null && (((activePlayer.trackTitle || "").trim() !== "") || ((activePlayer.trackArtist || "").trim() !== ""))

    spacing: Constants.sizeMd

    // Main Clock Display with contrast styling and settings respect
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: Constants.sizeXs

        ThemedText {
            text: {
                let t = SystemInfoService.currentTime;
                if (SettingsService.clock24h)
                    return Qt.formatTime(t, "HH");

                let h = t.getHours() % 12 || 12;
                return h.toString().padStart(2, "0");
            }
            customSize: 84
            font.weight: Font.DemiBold
            color: Theme.fg
        }

        ThemedText {
            id: colonText

            text: ":"
            customSize: 84
            font.weight: Font.Light
            color: Theme.accent
            opacity: colonTimer.colonVisible ? 1 : 0.25

            Timer {
                id: colonTimer

                property bool colonVisible: true

                interval: 1000
                running: true
                repeat: true
                onTriggered: colonVisible = !colonVisible
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: Constants.animNormal
                }

            }

        }

        ThemedText {
            text: Qt.formatTime(SystemInfoService.currentTime, "mm")
            customSize: 84
            font.weight: Font.Light
            color: Theme.accent
        }

        ThemedText {
            visible: SettingsService.clockSeconds
            text: Qt.formatTime(SystemInfoService.currentTime, ":ss")
            customSize: 42
            font.weight: Font.Light
            color: Theme.muted
            Layout.alignment: Qt.AlignBaseline
        }

        ThemedText {
            visible: !SettingsService.clock24h
            text: SystemInfoService.currentTime.getHours() >= 12 ? "PM" : "AM"
            customSize: 22
            font.weight: Font.Bold
            color: Theme.accent
            Layout.alignment: Qt.AlignBaseline
            Layout.leftMargin: Constants.sizeXs
        }

    }

    // Formatted Date (respects SettingsService.clockShowDate)
    ThemedText {
        Layout.alignment: Qt.AlignHCenter
        visible: SettingsService.clockShowDate
        text: Qt.formatDate(SystemInfoService.currentTime, "ddd · dd MMM · yyyy").toUpperCase()
        customSize: Constants.sizeSm
        font.letterSpacing: 3
        font.bold: true
        color: Theme.muted
    }

    // Now Playing Pill (if music is playing or available)
    Item {
        Layout.alignment: Qt.AlignHCenter
        visible: root.hasMedia
        implicitWidth: musicLayout.implicitWidth + Constants.sizeXl
        implicitHeight: Constants.size3Xl

        ThemedShadow {
            anchors.fill: musicPillBg
            radius: musicPillBg.radius
            active: true
            opacity: Theme.isDark ? 0.5 : 0.25
        }

        Rectangle {
            id: musicPillBg

            anchors.fill: parent
            radius: height / 2
            color: Theme.bg
            border.color: Theme.border
            border.width: 1

            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: parent.radius
                color: Theme.bgSecondary
            }

            RowLayout {
                id: musicLayout

                anchors.centerIn: parent
                spacing: Constants.sizeSm

                MiniCavaBars {
                    Layout.alignment: Qt.AlignVCenter
                    barColor: Theme.accent
                    maxBarHeight: Constants.sizeSm
                    minBarHeight: 3
                    barWidth: Constants.size3Xs
                    isPlaying: MprisService.isPlaying
                }

                ThemedText {
                    text: {
                        let p = root.activePlayer;
                        if (!p)
                            return "";

                        let artist = (p.trackArtist || "").trim();
                        let title = (p.trackTitle || "").trim();
                        return artist ? (artist + " — " + title) : title;
                    }
                    customSize: 11
                    color: Theme.fg
                    elide: Text.ElideRight
                    Layout.maximumWidth: 340
                }

            }

        }

    }

    // Quote (when music is not playing)
    ColumnLayout {
        Layout.alignment: Qt.AlignHCenter
        visible: !root.hasMedia
        spacing: Constants.size3Xs

        ThemedText {
            Layout.alignment: Qt.AlignHCenter
            text: QuoteService.currentQuote.text ? ("“" + QuoteService.currentQuote.text + "”") : ""
            customSize: 11
            font.italic: true
            color: Theme.muted
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            Layout.maximumWidth: 440
        }

        ThemedText {
            Layout.alignment: Qt.AlignHCenter
            visible: QuoteService.currentQuote.author !== ""
            text: QuoteService.currentQuote.author ? ("— " + QuoteService.currentQuote.author.toUpperCase()) : ""
            customSize: 9
            font.letterSpacing: 1.5
            color: Theme.muted
            opacity: 0.7
        }

    }

}
