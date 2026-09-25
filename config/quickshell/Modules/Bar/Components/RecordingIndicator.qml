import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Core
import qs.Core.Components
import qs.Core.Services

Item {
    id: root

    property int animationDuration: HyprlandService.enableAnimations ? Constants.animExpressive : 0
    readonly property var easeCurve: [0.25, 0.1, 0.25, 1, 1, 1]
    readonly property var overshotCurve: [0.13, 0.99, 0.29, 1.05, 1, 1]

    implicitWidth: contentRow.implicitWidth + 24
    implicitHeight: SettingsService.barWidgetHeight
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: SettingsService.barWidgetHeight
    clip: true
    states: [
        State {
            name: "running"
            when: RecorderService.running

            PropertyChanges {
                target: root
                Layout.preferredWidth: container.width
                opacity: 1
            }

        },
        State {
            name: "hidden"
            when: !RecorderService.running

            PropertyChanges {
                target: root
                Layout.preferredWidth: 0
                opacity: 0
            }

        }
    ]
    transitions: [
        Transition {
            from: "hidden"
            to: "running"

            NumberAnimation {
                property: "Layout.preferredWidth"
                duration: Constants.animNormal
                easing.type: Easing.OutQuint
            }

            NumberAnimation {
                property: "opacity"
                duration: Constants.animFast
                easing.type: Easing.Linear
            }

        },
        Transition {
            from: "running"
            to: "hidden"

            NumberAnimation {
                property: "Layout.preferredWidth"
                duration: Constants.animNormal
                easing.type: Easing.OutQuint
            }

            NumberAnimation {
                property: "opacity"
                duration: Constants.animFast
                easing.type: Easing.Linear
            }

        }
    ]

    Item {
        anchors.fill: parent
        clip: true

        Item {
            id: container

            width: innerRect.width
            height: innerRect.height
            anchors.centerIn: parent

            Rectangle {
                id: innerRect

                property bool isHovered: clickArea.containsMouse
                property bool isPressed: clickArea.pressed

                width: contentRow.implicitWidth + (SettingsService.isBarCompact ? 12 : 24)
                height: SettingsService.barWidgetHeight
                color: SettingsService.isBarCompact ? ((isHovered || isPressed) ? Theme.bgSecondary : "transparent") : ((isHovered || isPressed) ? Theme.bgTertiary : Theme.bgSecondary)
                radius: SettingsService.isBarCompact ? Constants.sizeMd : (height / 2)
                scale: isPressed ? 0.95 : (isHovered ? 1.02 : 1)

                Row {
                    id: contentRow

                    anchors.centerIn: parent
                    spacing: 8

                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: Theme.accentComplementary
                        anchors.verticalCenter: parent.verticalCenter

                        SequentialAnimation on opacity {
                            running: RecorderService.running
                            loops: Animation.Infinite

                            NumberAnimation {
                                to: 0.3
                                duration: 200
                                easing.type: Easing.OutSine
                            }

                            NumberAnimation {
                                to: 1
                                duration: 200
                                easing.type: Easing.InSine
                            }

                            PauseAnimation {
                                duration: 600
                            }

                        }

                    }

                    ThemedText {
                        id: timeText

                        text: RecorderService.formattedTime()
                        color: Theme.fg
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }

                }

                MouseArea {
                    id: clickArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        RecorderService.toggle([]);
                    }
                }

                Behavior on color {
                    ColorAnimation {
                        duration: Constants.animFast
                    }

                }

                Behavior on scale {
                    NumberAnimation {
                        duration: Constants.animFast
                        easing.type: Easing.OutBack
                    }

                }

            }

        }

    }

}
