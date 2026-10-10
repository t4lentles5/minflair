import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.Core
import qs.Core.Components
import qs.Core.Services

RowLayout {
    id: root

    spacing: Constants.sizeSm

    // System stats chip (CPU, RAM, Uptime)
    Item {
        implicitWidth: statsLayout.implicitWidth + Constants.sizeLg
        implicitHeight: 36

        ThemedShadow {
            anchors.fill: statsBg
            radius: statsBg.radius
            active: true
            opacity: Theme.isDark ? 0.5 : 0.25
        }

        Rectangle {
            id: statsBg

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
                id: statsLayout

                anchors.centerIn: parent
                spacing: Constants.sizeMd

                RowLayout {
                    spacing: Constants.sizeXs

                    SvgIcon {
                        icon: "cpu"
                        iconSize: 13
                        iconColor: Theme.accent
                        flat: true
                    }

                    ThemedText {
                        text: Math.round(SystemStats.cpuUsage) + "%"
                        customSize: 11
                        font.bold: true
                        color: Theme.fg
                    }

                }

                Rectangle {
                    width: 1
                    height: Constants.sizeMd
                    color: Theme.border
                }

                ThemedText {
                    text: "RAM " + SystemStats.memUsed.toFixed(1) + "G"
                    customSize: 11
                    color: Theme.muted
                }

                Rectangle {
                    width: 1
                    height: Constants.sizeMd
                    color: Theme.border
                }

                ThemedText {
                    text: "UP " + SystemStats.uptime
                    customSize: 11
                    color: Theme.muted
                }

            }

        }

    }

    // Power buttons chip
    Item {
        implicitWidth: powerLayout.implicitWidth + Constants.sizeSm
        implicitHeight: 36

        ThemedShadow {
            anchors.fill: powerBg
            radius: powerBg.radius
            active: true
            opacity: Theme.isDark ? 0.5 : 0.25
        }

        Rectangle {
            id: powerBg

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
                id: powerLayout

                anchors.centerIn: parent
                spacing: Constants.size3Xs

                SvgIconButton {
                    id: suspendBtn

                    icon: "moon"
                    iconSize: Constants.sizeMd
                    iconColor: Theme.fg
                    flat: true
                    onClicked: {
                        suspendProc.running = true;
                    }

                    ThemedTooltip {
                        visible: suspendBtn.hovered
                        text: "Suspend"
                    }

                }

                SvgIconButton {
                    id: powerBtn

                    icon: "power"
                    iconSize: Constants.sizeMd
                    iconColor: Theme.accentComplementary
                    flat: true
                    onClicked: {
                        powerProc.running = true;
                    }

                    ThemedTooltip {
                        visible: powerBtn.hovered
                        text: "Power Off"
                    }

                }

            }

        }

    }

    Process {
        id: suspendProc

        command: ["systemctl", "suspend"]
    }

    Process {
        id: powerProc

        command: ["systemctl", "poweroff"]
    }

}
