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
    useBorder: false

    RowLayout {
        id: heroLayout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Constants.sizeLg

        // Icon Container
        Rectangle {
            width: 52
            height: 52
            radius: Constants.sizeSm
            color: Theme.bgTertiary
            border.color: Theme.border
            border.width: 1
            Layout.alignment: Qt.AlignVCenter

            Image {
                id: pkgIcon

                anchors.fill: parent
                anchors.margins: Constants.sizeXs
                source: heroRoot.pkgName !== "" ? (Quickshell.iconPath(heroRoot.pkgName, true) || "") : ""
                sourceSize.width: 36
                sourceSize.height: 36
                visible: source.toString() !== ""
            }

            SvgIcon {
                icon: "box"
                iconSize: 24
                iconColor: Theme.muted
                anchors.centerIn: parent
                visible: !pkgIcon.visible
                flat: true
            }

        }

        // Title, badges, and quick description
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Constants.sizeXs
            Layout.alignment: Qt.AlignVCenter

            RowLayout {
                spacing: Constants.sizeSm
                Layout.fillWidth: true

                ThemedText {
                    text: heroRoot.pkgName
                    font.bold: true
                    customSize: Constants.sizeXl
                    color: Theme.fg
                }

                // Status Badge (Installed / Not Installed / Out-of-date)
                Rectangle {
                    readonly property bool isOutOfDate: !heroRoot.isInstalled && heroRoot.getValue("Out-of-date", "No") !== "No"

                    radius: Constants.sizeXs
                    implicitHeight: statusText.implicitHeight + 6
                    implicitWidth: statusText.implicitWidth + 14
                    color: heroRoot.isInstalled ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15) : (isOutOfDate ? Qt.rgba(Theme.accentComplementary.r, Theme.accentComplementary.g, Theme.accentComplementary.b, 0.15) : "transparent")
                    border.color: heroRoot.isInstalled ? Theme.accent : (isOutOfDate ? Theme.accentComplementary : Theme.border)
                    border.width: 1

                    ThemedText {
                        id: statusText

                        anchors.centerIn: parent
                        text: heroRoot.isInstalled ? "Installed" : (parent.isOutOfDate ? "Out-of-date" : "Not Installed")
                        customSize: Constants.sizeSm - 2
                        color: heroRoot.isInstalled ? Theme.accent : (parent.isOutOfDate ? Theme.accentComplementary : Theme.muted)
                        font.bold: true
                    }

                }

                Item {
                    Layout.fillWidth: true
                }

            }

            ThemedText {
                text: heroRoot.getValue("Description", "No description available")
                customSize: Constants.sizeSm
                color: Theme.muted
                wrapMode: Text.Wrap
                Layout.fillWidth: true
                maximumLineCount: 2
                elide: Text.ElideRight
            }

        }

    }

}
