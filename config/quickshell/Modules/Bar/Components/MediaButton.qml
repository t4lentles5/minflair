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
    readonly property bool hasMedia: trackTitle !== "" || trackArtist !== ""
    property bool isHovered: mouseArea.containsMouse
    property bool isPressed: mouseArea.pressed
    readonly property bool isCenteredBar: SettingsService.barIslandMode || SettingsService.barNotchMode

    implicitHeight: SettingsService.barWidgetHeight
    height: parent && parent.height > 0 ? parent.height : implicitHeight
    implicitWidth: root.hasMedia ? Math.min(300, contentRow.implicitWidth) : 0
    width: implicitWidth
    visible: root.hasMedia
    color: "transparent"
    scale: isPressed ? 0.95 : (isHovered ? 1.02 : 1)

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

            visible: root.hasMedia
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

            visible: root.hasMedia && root.trackArtist !== ""
            text: root.trackArtist
            elide: Text.ElideRight
            Layout.maximumWidth: root.trackTitle !== "" ? 100 : 200
            Layout.preferredWidth: Math.min(implicitWidth, Layout.maximumWidth)
        }

        ThemedText {
            id: separatorText

            visible: root.hasMedia && root.trackArtist !== "" && root.trackTitle !== ""
            text: "-"
            customSize: Constants.sizeMd
            font.bold: false
            color: Theme.accent
        }

        SlideText {
            id: titleText

            visible: root.hasMedia && root.trackTitle !== ""
            text: root.trackTitle
            elide: Text.ElideRight
            Layout.maximumWidth: root.trackArtist !== "" ? 120 : 200
            Layout.preferredWidth: Math.min(implicitWidth, Layout.maximumWidth)
        }

    }

    Behavior on scale {
        NumberAnimation {
            duration: Constants.animFast
            easing.type: Easing.OutQuad
        }

    }

}
