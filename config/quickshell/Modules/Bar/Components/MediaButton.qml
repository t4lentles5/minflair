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
    readonly property string displayTitle: trackTitle !== "" ? trackTitle : ((hideDebounceTimer.running || collapseProgress > 0.001) ? lastTrackTitle : "")
    readonly property string displayArtist: trackArtist !== "" ? trackArtist : ((hideDebounceTimer.running || collapseProgress > 0.001) ? lastTrackArtist : "")
    property real collapseProgress: hasMedia ? 1 : 0
    property bool isHovered: mouseArea.containsMouse
    property bool isPressed: mouseArea.pressed
    readonly property bool isCenteredBar: SettingsService.barIslandMode || SettingsService.barNotchMode
    property real lastContentWidth: 0
    readonly property real measuredWidth: contentRow.implicitWidth > 0 ? contentRow.implicitWidth : lastContentWidth
    readonly property real fullWidth: Math.min(300, measuredWidth)

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
    onMeasuredWidthChanged: {
        if (contentRow.implicitWidth > 0)
            lastContentWidth = contentRow.implicitWidth;

    }
    implicitHeight: SettingsService.barWidgetHeight
    height: parent && parent.height > 0 ? parent.height : implicitHeight
    implicitWidth: Math.round(fullWidth * collapseProgress)
    width: implicitWidth
    opacity: collapseProgress
    visible: collapseProgress > 0.001
    clip: collapseProgress < 0.999
    color: "transparent"
    scale: isPressed ? 0.95 : (isHovered ? 1.02 : 1)

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
                AppState.togglePopup("music");
            }
        }
    }

    RowLayout {
        id: contentRow

        anchors.centerIn: parent
        spacing: 4

        Row {
            id: visualizerRow

            readonly property var barIndices: [1, 3, 5, 9, 12, 16, 20, 25]

            visible: root.hasMedia || root.collapseProgress > 0.001
            spacing: 2
            width: implicitWidth
            height: 14
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: visible ? implicitWidth : 0
            Layout.rightMargin: 4

            Repeater {
                model: visualizerRow.barIndices

                Item {
                    required property int modelData
                    required property int index

                    width: 2
                    height: 14

                    Rectangle {
                        y: (parent.height - height) / 2
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 2
                        height: {
                            if (!MprisService.isPlaying)
                                return 3;

                            if (CavaService.cavaData && CavaService.cavaData.length > modelData)
                                return Math.max(3, Math.min(14, 3 + (CavaService.cavaData[modelData] / 100) * 11));

                            return 3;
                        }
                        radius: 1
                        color: Theme.accent

                        Behavior on height {
                            NumberAnimation {
                                duration: 150
                                easing.type: Easing.OutCubic
                            }

                        }

                    }

                }

            }

        }

        SlideText {
            id: artistText

            visible: (root.hasMedia || root.collapseProgress > 0.001) && root.displayArtist !== ""
            text: root.displayArtist
            elide: Text.ElideRight
            Layout.maximumWidth: root.displayTitle !== "" ? 100 : 200
            Layout.preferredWidth: Math.min(implicitWidth, Layout.maximumWidth)
        }

        ThemedText {
            id: separatorText

            visible: (root.hasMedia || root.collapseProgress > 0.001) && root.displayArtist !== "" && root.displayTitle !== ""
            text: "-"
            customSize: Constants.sizeMd
            font.bold: false
            color: Theme.accent
        }

        SlideText {
            id: titleText

            visible: (root.hasMedia || root.collapseProgress > 0.001) && root.displayTitle !== ""
            text: root.displayTitle
            elide: Text.ElideRight
            Layout.maximumWidth: root.displayArtist !== "" ? 120 : 200
            Layout.preferredWidth: Math.min(implicitWidth, Layout.maximumWidth)
        }

    }

    Behavior on collapseProgress {
        enabled: HyprlandService.enableAnimations

        NumberAnimation {
            duration: Constants.animNormal
            easing.type: Easing.OutCubic
        }

    }

    Behavior on scale {
        NumberAnimation {
            duration: Constants.animFast
            easing.type: Easing.OutQuad
        }

    }

}
