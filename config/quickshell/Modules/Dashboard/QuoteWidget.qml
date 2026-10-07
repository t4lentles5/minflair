import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Core
import qs.Core.Components
import qs.Core.Services

Item {
    id: root

    implicitHeight: mainLayout.implicitHeight
    implicitWidth: 350
    Layout.fillWidth: true
    state: "visible"
    states: [
        State {
            name: "visible"

            PropertyChanges {
                target: mainLayout
                opacity: 1
            }

        },
        State {
            name: "hidden"

            PropertyChanges {
                target: mainLayout
                opacity: 0
            }

        }
    ]
    transitions: [
        Transition {
            from: "visible"
            to: "hidden"

            NumberAnimation {
                property: "opacity"
                duration: Constants.animFast
            }

        },
        Transition {
            from: "hidden"
            to: "visible"

            NumberAnimation {
                property: "opacity"
                duration: Constants.animNormal
                easing.type: Easing.OutQuad
            }

        }
    ]

    Timer {
        id: cycleTimer

        interval: Constants.animFast
        repeat: false
        onTriggered: {
            QuoteService.generateRandomQuote();
            root.state = "visible";
        }
    }

    ThemedText {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: -Constants.sizeXs
        text: "“"
        customSize: Constants.size4Xl * 1.5
        font.family: Constants.fontFamily
        font.bold: true
        color: Theme.bgSecondary
    }

    MouseArea {
        id: clickArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.state === "visible") {
                root.state = "hidden";
                cycleTimer.start();
            }
        }
    }

    ColumnLayout {
        id: mainLayout

        anchors.fill: parent
        spacing: Constants.sizeXs

        TypewriterText {
            text: "“" + QuoteService.currentQuote.text + "”"
            customSize: Constants.sizeSm + 1
            font.family: Constants.fontFamily
            font.italic: true
            color: Theme.fg
            opacity: clickArea.containsMouse ? 1 : 0.85
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignLeft
            lineHeight: 1.2
            typeInterval: 20

            Behavior on opacity {
                NumberAnimation {
                    duration: Constants.animFast
                }

            }

        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Constants.sizeXs

            Item {
                Layout.fillWidth: true
            }

            Divider {
                implicitWidth: Constants.sizeSm
                Layout.fillWidth: false
            }

            TypewriterText {
                text: QuoteService.currentQuote.author
                customSize: Constants.sizeXs + 2
                color: Theme.muted
                Layout.alignment: Qt.AlignVCenter
                typeInterval: 40

                Behavior on opacity {
                    NumberAnimation {
                        duration: Constants.animFast
                    }

                }

            }

        }

    }

}
