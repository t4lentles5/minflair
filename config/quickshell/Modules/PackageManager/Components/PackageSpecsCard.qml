import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Core
import qs.Core.Components

Card {
    id: specsRoot

    property var parsedInfo: ({
    })

    function getValue(key, defaultVal) {
        return (parsedInfo && parsedInfo[key] !== undefined) ? parsedInfo[key] : defaultVal;
    }

    function formatDate(str) {
        if (!str)
            return "-";

        let parts = str.trim().split(/\s+/);
        if (parts.length >= 4 && isNaN(parts[0]))
            return parts[1] + " " + parts[2] + " " + parts[3];

        return str;
    }

    Layout.fillWidth: true
    cardRadius: Constants.sizeMd
    useBorder: false

    ColumnLayout {
        id: specsCol

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Constants.sizeSm

        ThemedText {
            text: "Information"
            font.bold: true
            customSize: Constants.sizeMd
            color: Theme.fg
        }

        // Spec Rows
        Repeater {
            model: [{
                "key": "Version",
                "val": specsRoot.getValue("Version", "")
            }, {
                "key": "Maintainer",
                "val": specsRoot.getValue("Maintainer", specsRoot.getValue("Packager", ""))
            }, {
                "key": "Licenses",
                "val": specsRoot.getValue("Licenses", "")
            }, {
                "key": "Architecture",
                "val": specsRoot.getValue("Architecture", "")
            }, {
                "key": "Download Size",
                "val": specsRoot.getValue("Download Size", "")
            }, {
                "key": "Installed Size",
                "val": specsRoot.getValue("Installed Size", "")
            }, {
                "key": "Install Date",
                "val": specsRoot.formatDate(specsRoot.getValue("Install Date", ""))
            }, {
                "key": "Build Date",
                "val": specsRoot.formatDate(specsRoot.getValue("Build Date", ""))
            }, {
                "key": "First Submitted",
                "val": specsRoot.formatDate(specsRoot.getValue("First Submitted", ""))
            }, {
                "key": "Last Modified",
                "val": specsRoot.formatDate(specsRoot.getValue("Last Modified", ""))
            }].filter((item) => {
                return item.val !== "" && item.val !== "None" && item.val !== "-";
            })

            delegate: RowLayout {
                Layout.fillWidth: true
                spacing: Constants.sizeSm

                ThemedText {
                    text: modelData.key
                    color: Theme.muted
                    customSize: Constants.sizeSm
                    Layout.preferredWidth: 105
                }

                ThemedText {
                    text: modelData.val
                    color: Theme.fg
                    customSize: Constants.sizeSm
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignRight
                }

            }

        }

        // AUR Community Stats (Votes & Popularity)
        RowLayout {
            Layout.fillWidth: true
            visible: specsRoot.parsedInfo["Votes"] !== undefined || specsRoot.parsedInfo["Popularity"] !== undefined
            spacing: Constants.sizeSm

            ThemedText {
                text: "AUR Stats"
                color: Theme.muted
                customSize: Constants.sizeSm
                Layout.preferredWidth: 105
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Constants.sizeSm
                Layout.alignment: Qt.AlignRight

                Item {
                    Layout.fillWidth: true
                }

                // Votes
                RowLayout {
                    spacing: 4
                    visible: specsRoot.parsedInfo["Votes"] !== undefined

                    SvgIcon {
                        icon: "star-filled"
                        iconSize: 12
                        iconColor: Theme.accent
                        flat: true
                    }

                    ThemedText {
                        text: specsRoot.getValue("Votes", "0")
                        customSize: Constants.sizeSm
                        color: Theme.fg
                        font.bold: true
                    }

                }

                // Popularity
                ThemedText {
                    text: "• " + Number(specsRoot.getValue("Popularity", "0")).toFixed(2)
                    customSize: Constants.sizeSm
                    color: Theme.muted
                    visible: specsRoot.parsedInfo["Popularity"] !== undefined
                }

            }

        }

    }

}
