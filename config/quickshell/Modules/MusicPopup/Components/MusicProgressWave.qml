import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.Mpris
import qs.Core
import qs.Core.Components
import qs.Core.Services

ColumnLayout {
    id: progressRoot

    property real wavePhase: 0
    property bool isVisibleOnScreen: true

    Layout.fillWidth: true
    spacing: 4
    Layout.topMargin: Constants.sizeXs

    Item {
        id: progressArea

        property real progress: (MprisService.activePlayer && MprisService.activePlayer.length > 0) ? (MprisService.activePlayer.position / MprisService.activePlayer.length) : 0

        Layout.fillWidth: true
        Layout.preferredHeight: 16

        Canvas {
            id: waveCanvas

            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                if (!MprisService.activePlayer)
                    return ;

                var p = Math.max(0, Math.min(1, progressArea.progress));
                var currentX = p * width;
                var midY = height / 2;
                // Draw wavy elapsed line
                ctx.beginPath();
                ctx.moveTo(0, midY);
                var amp = MprisService.isPlaying ? 2.5 : 0.8;
                var freq = 0.22;
                for (var x = 0; x <= currentX; x += 2) {
                    var y = midY + amp * Math.sin(x * freq + progressRoot.wavePhase);
                    ctx.lineTo(x, y);
                }
                ctx.strokeStyle = Theme.accent;
                ctx.lineWidth = 3;
                ctx.lineCap = "round";
                ctx.stroke();
                // Draw cursor pill
                ctx.beginPath();
                ctx.moveTo(currentX, midY - 6);
                ctx.lineTo(currentX, midY + 6);
                ctx.lineWidth = 4;
                ctx.strokeStyle = Theme.accent;
                ctx.lineCap = "round";
                ctx.stroke();
                // Draw remaining track
                if (currentX + 8 < width) {
                    ctx.beginPath();
                    ctx.moveTo(currentX + 8, midY);
                    ctx.lineTo(width, midY);
                    ctx.strokeStyle = Theme.muted;
                    ctx.lineWidth = 2;
                    ctx.lineCap = "round";
                    ctx.stroke();
                }
                // Terminal dot
                ctx.beginPath();
                ctx.arc(width - 2, midY, 2, 0, 2 * Math.PI);
                ctx.fillStyle = Theme.muted;
                ctx.fill();
            }
        }

        Timer {
            running: MprisService.isPlaying && progressRoot.isVisibleOnScreen
            interval: 16
            repeat: true
            onTriggered: waveCanvas.requestPaint()
        }

        Connections {
            function onPositionChanged() {
                waveCanvas.requestPaint();
            }

            target: MprisService.activePlayer
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onPositionChanged: (mouse) => {
                if (pressed && MprisService.activePlayer && MprisService.activePlayer.canSeek) {
                    var p = Math.max(0, Math.min(1, mouse.x / width));
                    MprisService.activePlayer.position = p * MprisService.activePlayer.length;
                }
            }
            onClicked: (mouse) => {
                if (MprisService.activePlayer && MprisService.activePlayer.canSeek) {
                    var p = Math.max(0, Math.min(1, mouse.x / width));
                    MprisService.activePlayer.position = p * MprisService.activePlayer.length;
                }
            }
        }

    }

    RowLayout {
        Layout.fillWidth: true

        ThemedText {
            text: MprisService.formatTime(MprisService.activePlayer ? MprisService.activePlayer.position : 0)
            customSize: Constants.sizeXs
            color: Theme.muted
        }

        Item {
            Layout.fillWidth: true
        }

        ThemedText {
            text: MprisService.formatTime(MprisService.activePlayer ? MprisService.activePlayer.length : 0)
            customSize: Constants.sizeXs
            color: Theme.muted
        }

    }

}
