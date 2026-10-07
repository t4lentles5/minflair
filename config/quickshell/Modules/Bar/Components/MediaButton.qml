import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import qs.Core
import qs.Core.Components
import qs.Core.Services

Rectangle {
    id: root

    readonly property bool hasPlayer: MprisService.activePlayer !== null
    readonly property bool isPlaying: MprisService.isPlaying
    readonly property string trackTitle: hasPlayer ? (MprisService.activePlayer.trackTitle || "").trim() : ""
    readonly property string trackArtist: hasPlayer ? (MprisService.activePlayer.trackArtist || "").trim() : ""
    readonly property bool rawHasMedia: hasPlayer && (trackTitle !== "" || trackArtist !== "")
    property bool hasMedia: rawHasMedia
    property string lastTrackTitle: ""
    property string lastTrackArtist: ""
    readonly property string displayTitle: trackTitle !== "" ? trackTitle : (hideDebounceTimer.running ? lastTrackTitle : "")
    readonly property string displayArtist: trackArtist !== "" ? trackArtist : (hideDebounceTimer.running ? lastTrackArtist : "")
    property bool isHovered: mouseArea.containsMouse
    property bool isPressed: mouseArea.pressed
    readonly property bool isCenteredBar: SettingsService.barIslandMode
    readonly property real fullWidth: Math.min(300, contentRow.implicitWidth)

    onTrackTitleChanged: {
        if (trackTitle !== "")
            lastTrackTitle = trackTitle;

    }
    onTrackArtistChanged: {
        if (trackArtist !== "")
            lastTrackArtist = trackArtist;

    }
    onRawHasMediaChanged: {
        if (rawHasMedia) {
            hideDebounceTimer.stop();
            hasMedia = true;
        } else {
            hideDebounceTimer.restart();
        }
    }
    implicitHeight: SettingsService.barWidgetHeight
    height: parent && parent.height > 0 ? parent.height : implicitHeight
    implicitWidth: hasMedia ? fullWidth : 0
    width: implicitWidth
    opacity: hasMedia ? 1 : 0
    visible: hasMedia || opacity > 0.001
    clip: true
    color: "transparent"
    scale: DisplayProfileService.gameModeActive ? 1 : (isPressed ? 0.95 : (isHovered ? 1.02 : 1))

    Timer {
        id: hideDebounceTimer

        interval: 350
        repeat: false
        onTriggered: {
            if (!root.rawHasMedia)
                root.hasMedia = false;

        }
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                if (root.hasPlayer)
                    MprisService.activePlayer.togglePlaying();
                else
                    MprisService.launchPlayer();
            } else {
                AppState.toggleWidget("music");
            }
        }
    }

    RowLayout {
        id: contentRow

        anchors.centerIn: parent
        spacing: Constants.size2Xs

        MiniCavaBars {
            id: visualizerRow

            visible: root.hasMedia
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: visible ? implicitWidth : 0
            Layout.rightMargin: Constants.size2Xs
            opacity: MprisService.isPlaying ? 1 : 0.45

            Behavior on opacity {
                NumberAnimation {
                    duration: Constants.animFast
                    easing.type: Easing.OutCubic
                }

            }

        }

        ThemedText {
            id: artistText

            visible: root.hasMedia && root.displayArtist !== ""
            text: root.displayArtist
            elide: Text.ElideRight
            Layout.maximumWidth: root.displayTitle !== "" ? 100 : 200
            Layout.preferredWidth: Math.min(implicitWidth, Layout.maximumWidth)
        }

        ThemedText {
            id: separatorText

            visible: root.hasMedia && root.displayArtist !== "" && root.displayTitle !== ""
            text: "-"
            customSize: Constants.sizeMd
            font.bold: false
            color: Theme.accent
        }

        ThemedText {
            id: titleText

            visible: root.hasMedia && root.displayTitle !== ""
            text: root.displayTitle
            elide: Text.ElideRight
            Layout.maximumWidth: root.displayArtist !== "" ? 120 : 200
            Layout.preferredWidth: Math.min(implicitWidth, Layout.maximumWidth)
        }

    }

    Behavior on opacity {
        enabled: HyprlandService.enableAnimations

        NumberAnimation {
            duration: Constants.animFast
            easing.type: Easing.OutCubic
        }

    }

    Behavior on scale {
        NumberAnimation {
            duration: Constants.animFast
            easing.type: Easing.OutBack
        }

    }

}
