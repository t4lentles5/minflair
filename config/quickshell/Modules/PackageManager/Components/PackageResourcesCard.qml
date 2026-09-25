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
    cardRadius: Constants.sizeMd
    useBorder: false
    visible: resRoot.getValue("URL", "") !== "" || resRoot.getValue("AUR URL", "") !== ""

    ColumnLayout {
        id: linksCol

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Constants.sizeSm

        ThemedText {
            text: "Resources"
            font.bold: true
            customSize: Constants.sizeMd
            color: Theme.fg
        }

        // Project Homepage
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 52
            radius: Constants.sizeSm
            color: projectHover.hovered ? Theme.bgTertiary : "transparent"
            border.width: 1
            border.color: projectHover.hovered ? Theme.accent : Theme.border
            visible: resRoot.getValue("URL", "") !== ""

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Constants.sizeMd
                anchors.rightMargin: Constants.sizeMd
                spacing: Constants.sizeSm

                Item {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    Layout.alignment: Qt.AlignVCenter

                    SvgIcon {
                        icon: "code"
                        iconSize: 16
                        iconColor: Theme.accent
                        flat: true
                        anchors.centerIn: parent
                    }

                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    ThemedText {
                        text: "Project Website"
                        font.bold: true
                        customSize: Constants.sizeSm
                        color: Theme.fg
                    }

                    ThemedText {
                        text: resRoot.cleanUrl(resRoot.getValue("URL", ""))
                        customSize: Constants.sizeXs + 2
                        color: Theme.muted
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                }

                SvgIcon {
                    icon: "chevron-right"
                    iconSize: 14
                    iconColor: Theme.muted
                    flat: true
                }

            }

            HoverHandler {
                id: projectHover

                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: Qt.openUrlExternally(resRoot.getValue("URL", ""))
            }

        }

        // AUR Package Page
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 52
            radius: Constants.sizeSm
            color: aurHover.hovered ? Theme.bgTertiary : "transparent"
            border.width: 1
            border.color: aurHover.hovered ? Theme.accent : Theme.border
            visible: resRoot.getValue("AUR URL", "") !== ""

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Constants.sizeMd
                anchors.rightMargin: Constants.sizeMd
                spacing: Constants.sizeSm

                Item {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    Layout.alignment: Qt.AlignVCenter

                    SvgIcon {
                        icon: "box"
                        iconSize: 16
                        iconColor: Theme.accent
                        flat: true
                        anchors.centerIn: parent
                    }

                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    ThemedText {
                        text: "AUR Package Page"
                        font.bold: true
                        customSize: Constants.sizeSm
                        color: Theme.fg
                    }

                    ThemedText {
                        text: "aur.archlinux.org"
                        customSize: Constants.sizeXs + 2
                        color: Theme.muted
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                }

                SvgIcon {
                    icon: "chevron-right"
                    iconSize: 14
                    iconColor: Theme.muted
                    flat: true
                }

            }

            HoverHandler {
                id: aurHover

                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: Qt.openUrlExternally(resRoot.getValue("AUR URL", ""))
            }

        }

    }

}
