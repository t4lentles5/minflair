import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Core
import qs.Core.Components
import qs.Core.Services

Item {
    id: lyricsPanel

    property bool isExpanded: false
    readonly property bool shouldShow: isExpanded && LyricsService.hasLyrics

    Layout.fillHeight: true
    Layout.preferredWidth: shouldShow ? 320 : 0
    visible: shouldShow
    opacity: shouldShow ? 1 : 0

    Rectangle {
        anchors.fill: parent
        color: Theme.bgSecondary
        radius: Constants.sizeLg
        clip: true

        // Header
        RowLayout {
            id: lyricsHeader

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Constants.sizeLg

            ThemedText {
                text: "Lyrics"
                customSize: Constants.sizeLg
                font.bold: true
                color: Theme.fg
                Layout.fillWidth: true
            }

            Rectangle {
                color: Theme.accentComplementary
                radius: 6
                width: syncedText.implicitWidth + 12
                height: syncedText.implicitHeight + 4
                visible: LyricsService.isSynced

                ThemedText {
                    id: syncedText

                    anchors.centerIn: parent
                    text: "SYNCED"
                    customSize: Constants.sizeXs
                    font.bold: true
                    color: Theme.bg
                }

            }

        }

        // Loading State
        ThemedText {
            anchors.centerIn: parent
            text: "Loading lyrics..."
            customSize: Constants.sizeMd
            color: Theme.muted
            visible: LyricsService.loading
        }

        // Synced Lyrics View
        ListView {
            id: lyricsList

            anchors.top: lyricsHeader.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Constants.sizeMd
            topMargin: Constants.sizeSm
            bottomMargin: Constants.sizeSm
            visible: !LyricsService.loading && LyricsService.hasLyrics && LyricsService.isSynced
            model: LyricsService.lines
            spacing: Constants.sizeSm
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            highlightFollowsCurrentItem: true
            highlightMoveDuration: Constants.animSlow
            highlightMoveVelocity: -1
            preferredHighlightBegin: Math.max(topMargin + 20, Math.round(lyricsList.height / 2 - 20))
            preferredHighlightEnd: Math.max(topMargin + 60, Math.round(lyricsList.height / 2 + 20))
            highlightRangeMode: LyricsService.currentLineIndex > 0 ? ListView.ApplyRange : ListView.NoHighlightRange
            onVisibleChanged: {
                if (visible) {
                    if (LyricsService.currentLineIndex <= 0) {
                        currentIndex = 0;
                        contentY = -topMargin;
                    } else {
                        currentIndex = LyricsService.currentLineIndex;
                    }
                }
            }
            onModelChanged: {
                if (LyricsService.currentLineIndex <= 0) {
                    currentIndex = 0;
                    contentY = -topMargin;
                } else {
                    currentIndex = LyricsService.currentLineIndex;
                }
            }

            Connections {
                function onCurrentLineIndexChanged() {
                    if (!lyricsList.dragging && !lyricsMouse.pressed) {
                        if (LyricsService.currentLineIndex <= 0) {
                            lyricsList.currentIndex = 0;
                            lyricsList.contentY = -lyricsList.topMargin;
                        } else {
                            lyricsList.currentIndex = LyricsService.currentLineIndex;
                        }
                    }
                }

                target: LyricsService
            }

            MouseArea {
                id: lyricsMouse

                anchors.fill: parent
                propagateComposedEvents: true
                onWheel: (wheel) => {
                    wheel.accepted = false;
                }
                onPressed: (mouse) => {
                    mouse.accepted = false;
                }
                onReleased: (mouse) => {
                    mouse.accepted = false;
                }
            }

            highlight: Item {
            }

            delegate: Item {
                id: lineItem

                property bool isCurrent: LyricsService.currentLineIndex === index

                width: ListView.view.width
                height: lineText.implicitHeight + Constants.size2Xs

                ThemedText {
                    id: lineText

                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.right: parent.right
                    text: modelData.text
                    horizontalAlignment: Text.AlignLeft
                    wrapMode: Text.WordWrap
                    customSize: Constants.sizeMd + 1
                    font.weight: isCurrent ? Font.DemiBold : Font.Normal
                    color: isCurrent ? Theme.fg : Theme.muted
                    opacity: isCurrent ? 1 : 0.3
                    anchors.leftMargin: isCurrent ? 6 : 0
                    transformOrigin: Item.Left

                    Behavior on anchors.leftMargin {
                        NumberAnimation {
                            duration: Constants.animSlow
                            easing.type: Easing.OutCubic
                        }

                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: Constants.animSlow
                            easing.type: Easing.OutCubic
                        }

                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Constants.animSlow
                            easing.type: Easing.OutCubic
                        }

                    }

                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        LyricsService.seekToLine(index);
                        lyricsList.currentIndex = index;
                    }
                }

            }

        }

        // Plain Lyrics View
        Flickable {
            anchors.top: lyricsHeader.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Constants.sizeMd
            visible: !LyricsService.loading && LyricsService.hasLyrics && !LyricsService.isSynced
            contentWidth: width
            contentHeight: plainText.implicitHeight
            clip: true

            ThemedText {
                id: plainText

                width: parent.width
                text: LyricsService.plainLyrics
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                customSize: Constants.sizeMd
                color: Theme.fg
            }

        }

    }

    Behavior on opacity {
        NumberAnimation {
            duration: Constants.animNormal
        }

    }

}
