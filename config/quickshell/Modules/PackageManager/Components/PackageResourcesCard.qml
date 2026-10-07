import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Core
import qs.Core.Components

Card {
    id: resRoot

    property var parsedInfo: ({
    })

    function getValue(key, defaultVal) {
        return (parsedInfo && parsedInfo[key] !== undefined) ? parsedInfo[key] : defaultVal;
    }

    function cleanUrl(url) {
        if (!url)
            return "";

        return url.replace(/^https?:\/\//i, "").replace(/\/$/, "");
    }

    Layout.fillWidth: true
    cardRadius: Constants.sizeSm
    useBorder: true
    borderColor: Theme.border
    backgroundColor: Theme.bgSecondary
    contentPadding: Constants.sizeLg
    visible: resRoot.getValue("URL", "") !== "" || resRoot.getValue("AUR URL", "") !== ""

    ColumnLayout {
        id: linksCol

        anchors.fill: parent
        spacing: Constants.sizeSm

        RowLayout {
            spacing: Constants.sizeXs
            Layout.bottomMargin: Constants.size3Xs

            SvgIcon {
                icon: "code"
                iconSize: Constants.sizeMd
                iconColor: Theme.muted
                flat: true
            }

            ThemedText {
                text: "RESOURCES"
                font.bold: true
                font.letterSpacing: 0.8
                customSize: 10
                color: Theme.muted
            }

        }

        // Project Homepage
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Constants.size5Xl
            radius: Constants.sizeXs
            color: projectHover.hovered ? Theme.bgSecondary : Theme.bgTertiary
            border.width: 1
            border.color: projectHover.hovered ? Theme.accent : Theme.border
            visible: resRoot.getValue("URL", "") !== ""

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Constants.sizeMd
                anchors.rightMargin: Constants.sizeMd
                spacing: Constants.sizeSm

                Item {
                    Layout.preferredWidth: Constants.size2Xl
                    Layout.preferredHeight: Constants.size2Xl
                    Layout.alignment: Qt.AlignVCenter

                    SvgIcon {
                        icon: "code"
                        iconSize: Constants.sizeLg
                        iconColor: projectHover.hovered ? Theme.accent : Theme.muted
                        flat: true
                        anchors.centerIn: parent

                        Behavior on iconColor {
                            ColorAnimation {
                                duration: Constants.animFast
                            }

                        }

                    }

                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    ThemedText {
                        text: "Project Website"
                        font.bold: true
                        customSize: Constants.sizeSm
                        color: projectHover.hovered ? Theme.accent : Theme.fg

                        Behavior on color {
                            ColorAnimation {
                                duration: Constants.animFast
                            }

                        }

                    }

                    ThemedText {
                        text: resRoot.cleanUrl(resRoot.getValue("URL", ""))
                        customSize: Constants.sizeXs + 1
                        color: Theme.muted
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                }

                SvgIcon {
                    icon: "chevron-right"
                    iconSize: Constants.sizeMd
                    iconColor: projectHover.hovered ? Theme.accent : Theme.muted
                    flat: true

                    Behavior on iconColor {
                        ColorAnimation {
                            duration: Constants.animFast
                        }

                    }

                }

            }

            HoverHandler {
                id: projectHover

                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: Qt.openUrlExternally(resRoot.getValue("URL", ""))
            }

            Behavior on color {
                ColorAnimation {
                    duration: Constants.animFast
                }

            }

            Behavior on border.color {
                ColorAnimation {
                    duration: Constants.animFast
                }

            }

        }

        // AUR Package Page
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Constants.size5Xl
            radius: Constants.sizeXs
            color: aurHover.hovered ? Theme.bgSecondary : Theme.bgTertiary
            border.width: 1
            border.color: aurHover.hovered ? Theme.accent : Theme.border
            visible: resRoot.getValue("AUR URL", "") !== ""

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Constants.sizeMd
                anchors.rightMargin: Constants.sizeMd
                spacing: Constants.sizeSm

                Item {
                    Layout.preferredWidth: Constants.size2Xl
                    Layout.preferredHeight: Constants.size2Xl
                    Layout.alignment: Qt.AlignVCenter

                    SvgIcon {
                        icon: "box"
                        iconSize: Constants.sizeLg
                        iconColor: aurHover.hovered ? Theme.accent : Theme.muted
                        flat: true
                        anchors.centerIn: parent

                        Behavior on iconColor {
                            ColorAnimation {
                                duration: Constants.animFast
                            }

                        }

                    }

                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    ThemedText {
                        text: "AUR Package Page"
                        font.bold: true
                        customSize: Constants.sizeSm
                        color: aurHover.hovered ? Theme.accent : Theme.fg

                        Behavior on color {
                            ColorAnimation {
                                duration: Constants.animFast
                            }

                        }

                    }

                    ThemedText {
                        text: "aur.archlinux.org"
                        customSize: Constants.sizeXs + 1
                        color: Theme.muted
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                }

                SvgIcon {
                    icon: "chevron-right"
                    iconSize: Constants.sizeMd
                    iconColor: aurHover.hovered ? Theme.accent : Theme.muted
                    flat: true

                    Behavior on iconColor {
                        ColorAnimation {
                            duration: Constants.animFast
                        }

                    }

                }

            }

            HoverHandler {
                id: aurHover

                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: Qt.openUrlExternally(resRoot.getValue("AUR URL", ""))
            }

            Behavior on color {
                ColorAnimation {
                    duration: Constants.animFast
                }

            }

            Behavior on border.color {
                ColorAnimation {
                    duration: Constants.animFast
                }

            }

        }

    }

}
