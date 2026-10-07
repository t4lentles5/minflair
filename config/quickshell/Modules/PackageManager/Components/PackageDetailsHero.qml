import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Core
import qs.Core.Components
import qs.Core.Utils

Card {
    id: heroRoot

    property string pkgName: ""
    property var parsedInfo: ({
    })
    property bool isInstalled: false
    property bool isSelected: false
    property var managerRoot

    function getValue(key, defaultVal) {
        return (parsedInfo && parsedInfo[key] !== undefined) ? parsedInfo[key] : defaultVal;
    }

    Layout.fillWidth: true
    cardRadius: Constants.sizeMd
    useBorder: true
    borderColor: Theme.border
    backgroundColor: Theme.bgSecondary
    contentPadding: Constants.sizeXl

    RowLayout {
        id: heroLayout

        anchors.fill: parent
        spacing: Constants.sizeXl

        // Large App Icon
        Rectangle {
            width: 64
            height: 64
            radius: Constants.sizeSm
            color: Theme.bgTertiary
            border.color: Theme.border
            border.width: 1
            Layout.alignment: Qt.AlignTop

            Image {
                id: pkgIcon

                anchors.centerIn: parent
                source: heroRoot.pkgName !== "" ? (Quickshell.iconPath(heroRoot.pkgName, true) || "") : ""
                sourceSize.width: Constants.size4Xl
                sourceSize.height: Constants.size4Xl
                visible: source.toString() !== ""
            }

            SvgIcon {
                icon: "box"
                iconSize: 30
                iconColor: Theme.muted
                anchors.centerIn: parent
                visible: !pkgIcon.visible
                flat: true
            }

        }

        // Details Column
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Constants.sizeSm
            Layout.alignment: Qt.AlignTop

            // Top Header: Title + Badges + Action Buttons
            RowLayout {
                Layout.fillWidth: true
                spacing: Constants.sizeSm

                ThemedText {
                    text: heroRoot.pkgName
                    font.bold: true
                    customSize: 22
                    color: Theme.fg
                }

                // Version Badge
                Rectangle {
                    visible: heroRoot.getValue("Version", "") !== ""
                    radius: Constants.sizeXs
                    implicitHeight: Constants.size2Xl
                    implicitWidth: versionText.implicitWidth + Constants.sizeMd
                    color: Theme.bgSecondary
                    border.color: Theme.border
                    border.width: 1
                    Layout.alignment: Qt.AlignVCenter

                    ThemedText {
                        id: versionText

                        anchors.centerIn: parent
                        text: heroRoot.getValue("Version", "")
                        customSize: Constants.sizeXs
                        color: Theme.fg
                    }

                }

                // Status Badge (Installed / Not Installed / Out-of-date)
                Rectangle {
                    readonly property bool isOutOfDate: !heroRoot.isInstalled && heroRoot.getValue("Out-of-date", "No") !== "No"

                    radius: Constants.sizeXs
                    implicitHeight: Constants.size2Xl
                    implicitWidth: statusLayout.implicitWidth + 14
                    color: heroRoot.isInstalled ? Theme.bgAccent : (isOutOfDate ? Theme.bgAccentComplementary : Theme.bgSecondary)
                    border.color: heroRoot.isInstalled ? "transparent" : (isOutOfDate ? "transparent" : Theme.border)
                    border.width: 1
                    Layout.alignment: Qt.AlignVCenter

                    RowLayout {
                        id: statusLayout

                        anchors.centerIn: parent
                        spacing: 5

                        Rectangle {
                            width: 6
                            height: 6
                            radius: height / 2
                            color: heroRoot.isInstalled ? Theme.accent : (parent.parent.isOutOfDate ? Theme.accentComplementary : Theme.fg)
                            visible: heroRoot.isInstalled || parent.parent.isOutOfDate
                        }

                        ThemedText {
                            text: heroRoot.isInstalled ? "Installed" : (parent.parent.isOutOfDate ? "Out-of-date" : "Not Installed")
                            customSize: Constants.sizeXs
                            color: heroRoot.isInstalled ? Theme.accent : (parent.parent.isOutOfDate ? Theme.accentComplementary : Theme.fg)
                            font.bold: heroRoot.isInstalled
                        }

                    }

                }

                Item {
                    Layout.fillWidth: true
                }

                // Batch Selection Button
                Rectangle {
                    visible: heroRoot.managerRoot !== null
                    width: Constants.size2Xl + 6
                    height: Constants.size2Xl + 6
                    radius: Constants.sizeXs
                    color: heroRoot.isSelected ? Theme.accent : (batchHover.hovered ? Theme.bgSecondary : "transparent")
                    border.width: heroRoot.isSelected ? 0 : 1
                    border.color: heroRoot.isSelected ? Theme.accent : Theme.border
                    Layout.alignment: Qt.AlignVCenter

                    SvgIcon {
                        anchors.centerIn: parent
                        icon: "check"
                        iconSize: Constants.sizeMd
                        iconColor: heroRoot.isSelected ? Theme.bg : Theme.muted
                        flat: true
                    }

                    HoverHandler {
                        id: batchHover

                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        onTapped: {
                            if (heroRoot.managerRoot)
                                heroRoot.managerRoot.toggleSelect(heroRoot.pkgName);

                        }
                    }

                }

            }

            // Description
            ThemedText {
                text: heroRoot.getValue("Description", "No description available")
                customSize: Constants.sizeSm
                color: Theme.fg
                opacity: 0.85
                wrapMode: Text.Wrap
                Layout.fillWidth: true
                maximumLineCount: 2
                elide: Text.ElideRight
            }

            // Quick Metadata Pills Row
            RowLayout {
                Layout.fillWidth: true
                spacing: Constants.sizeXs
                Layout.topMargin: Constants.size3Xs

                // Repository / Source Tag
                Rectangle {
                    visible: heroRoot.getValue("Repository", "") !== ""
                    implicitHeight: Constants.size2Xl
                    implicitWidth: repoTagText.implicitWidth + 14
                    radius: Constants.sizeXs
                    color: Theme.bgAccentComplementary
                    border.color: Theme.border
                    border.width: 1

                    ThemedText {
                        id: repoTagText

                        anchors.centerIn: parent
                        text: heroRoot.getValue("Repository", "").toUpperCase()
                        customSize: Constants.sizeXs
                        font.bold: true
                        color: Theme.muted
                    }

                }

                // Size Tag
                Rectangle {
                    visible: heroRoot.getValue("Installed Size", heroRoot.getValue("Download Size", "")) !== ""
                    implicitHeight: Constants.size2Xl
                    implicitWidth: sizeTagText.implicitWidth + 14
                    radius: Constants.sizeXs
                    color: Theme.bgSecondary
                    border.color: Theme.border
                    border.width: 1

                    ThemedText {
                        id: sizeTagText

                        anchors.centerIn: parent
                        text: heroRoot.getValue("Installed Size", heroRoot.getValue("Download Size", ""))
                        customSize: Constants.sizeXs
                        color: Theme.muted
                    }

                }

                // License Tag
                Rectangle {
                    visible: heroRoot.getValue("Licenses", "") !== ""
                    implicitHeight: Constants.size2Xl
                    implicitWidth: licenseTagText.implicitWidth + 14
                    radius: Constants.sizeXs
                    color: Theme.bgSecondary
                    border.color: Theme.border
                    border.width: 1

                    ThemedText {
                        id: licenseTagText

                        anchors.centerIn: parent
                        text: heroRoot.getValue("Licenses", "")
                        customSize: Constants.sizeXs
                        color: Theme.muted
                    }

                }

                // Architecture Tag
                Rectangle {
                    visible: heroRoot.getValue("Architecture", "") !== ""
                    implicitHeight: Constants.size2Xl
                    implicitWidth: archTagText.implicitWidth + Constants.sizeMd
                    radius: Constants.sizeXs
                    color: Theme.bgSecondary
                    border.color: Theme.border
                    border.width: 1

                    ThemedText {
                        id: archTagText

                        anchors.centerIn: parent
                        text: heroRoot.getValue("Architecture", "")
                        customSize: Constants.sizeXs
                        color: Theme.muted
                    }

                }

                Item {
                    Layout.fillWidth: true
                }

            }

        }

    }

}
