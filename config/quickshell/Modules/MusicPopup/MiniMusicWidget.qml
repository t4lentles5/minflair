import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.MusicPopup.Components

Item {
    id: root

    property var widget: null
    property real wavePhase: 0
    property var cavaData: CavaService.cavaData
    readonly property real artSize: 164
    readonly property real playerWidth: 240
    readonly property real lyricsWidth: 320
    property bool isExpanded: true
    readonly property bool isVisibleOnScreen: widget !== null && widget.isOpen !== undefined ? widget.isOpen : true

    implicitWidth: isExpanded ? (playerWidth + mainRow.spacing + lyricsWidth) : playerWidth
    implicitHeight: playerColumn.implicitHeight
    width: implicitWidth
    height: implicitHeight

    Timer {
        running: MprisService.isPlaying && root.isVisibleOnScreen
        interval: 16
        repeat: true
        onTriggered: root.wavePhase += 0.05
    }

    RowLayout {
        id: mainRow

        anchors.fill: parent
        spacing: Constants.sizeLg

        // PLAYER CARD COLUMN
        ColumnLayout {
            id: playerColumn

            Layout.preferredWidth: root.playerWidth
            Layout.fillWidth: false
            Layout.fillHeight: false
            spacing: Constants.sizeSm

            // TOP HEADER: Application Name + Lyrics Toggle Button
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 28

                Rectangle {
                    visible: true
                    color: (!SettingsService.musicPlayer || SettingsService.musicPlayer === "" || SettingsService.musicPlayer === "none") ? Theme.accent : Theme.bgSecondary
                    radius: 12
                    Layout.preferredHeight: 24
                    Layout.preferredWidth: badgeLbl.implicitWidth + 24

                    ThemedText {
                        id: badgeLbl

                        anchors.centerIn: parent
                        text: (!SettingsService.musicPlayer || SettingsService.musicPlayer === "" || SettingsService.musicPlayer === "none") ? "Configure Player" : (MprisService.activePlayerName !== "" ? MprisService.activePlayerName : MprisService.getDisplayName(SettingsService.musicPlayer))
                        customSize: Constants.sizeXs + 2
                        font.bold: true
                        color: (!SettingsService.musicPlayer || SettingsService.musicPlayer === "" || SettingsService.musicPlayer === "none") ? Theme.bg : Theme.fg
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        enabled: (!SettingsService.musicPlayer || SettingsService.musicPlayer === "" || SettingsService.musicPlayer === "none")
                        onClicked: {
                            AppState.pendingSettingsTab = 4;
                            AppState.openPopup("minflair_settings");
                        }
                    }

                }

                Item {
                    Layout.fillWidth: true
                }

                SvgIconButton {
                    id: lyricsTopBtn

                    icon: "quote"
                    iconSize: Constants.sizeSm
                    flat: true
                    isActive: root.isExpanded
                    iconColor: isActive ? Theme.accent : Theme.fg
                    onClicked: root.isExpanded = !root.isExpanded
                }

            }

            // COVER ART
            Item {
                id: artSection

                Layout.preferredWidth: root.artSize
                Layout.preferredHeight: root.artSize
                Layout.alignment: Qt.AlignHCenter

                Image {
                    id: artImage

                    anchors.fill: parent
                    source: MprisService.activePlayer ? (MprisService.activePlayer.trackArtUrl || "") : ""
                    fillMode: Image.PreserveAspectCrop
                    mipmap: true
                    asynchronous: true
                    visible: false
                }

                Rectangle {
                    id: artMask

                    anchors.fill: parent
                    radius: 16
                    visible: false
                }

                OpacityMask {
                    anchors.fill: parent
                    source: artImage
                    maskSource: artMask
                    visible: artImage.status === Image.Ready && MprisService.activePlayer !== null
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 16
                    color: Theme.bgSecondary
                    visible: artImage.status !== Image.Ready || MprisService.activePlayer === null

                    SvgIcon {
                        anchors.centerIn: parent
                        icon: "music"
                        iconSize: parent.width * 0.4
                        iconColor: Theme.accent
                        flat: true
                    }

                }

            }

            // METADATA
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                TypewriterText {
                    text: MprisService.activePlayer ? (MprisService.activePlayer.trackTitle || "Not Playing") : "No Music"
                    customSize: Constants.sizeLg
                    font.weight: Font.Bold
                    color: Theme.fg
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                }

                TypewriterText {
                    text: MprisService.activePlayer ? (MprisService.activePlayer.trackArtist || "Unknown Artist") : ((!SettingsService.musicPlayer || SettingsService.musicPlayer === "" || SettingsService.musicPlayer === "none") ? "Click below to configure" : "Open a music player to get started")
                    customSize: Constants.sizeSm
                    color: Theme.accentComplementary
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                }

            }

            // PROGRESS BAR (Wavy)
            MusicProgressWave {
                wavePhase: root.wavePhase
                isVisibleOnScreen: root.isVisibleOnScreen
            }

            // CONTROLS
            MusicPlayerControls {
                currentLoopState: {
                    if (!MprisService.activePlayer || !MprisService.activePlayer.loopSupported)
                        return 0;

                    return MprisService.activePlayer.loopState;
                }
                isShuffleActive: {
                    if (!MprisService.activePlayer || !MprisService.activePlayer.shuffleSupported)
                        return false;

                    return MprisService.activePlayer.shuffle;
                }
            }

            // CAVA VISUALIZER BOTTOM
            MusicCavaBars {
                cavaData: root.cavaData
            }

        }

        // RIGHT LYRICS VIEW
        MusicLyricsPanel {
            isExpanded: root.isExpanded
            Layout.preferredWidth: root.lyricsWidth
        }

    }

    Behavior on implicitWidth {
        enabled: HyprlandService.enableAnimations

        NumberAnimation {
            duration: Constants.animNormal
            easing.type: Easing.OutQuint
        }

    }

}
