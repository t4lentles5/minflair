import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Core
import qs.Core.Components

Card {
    id: relRoot

    property var parsedInfo: ({
    })

    function getValue(key, defaultVal) {
        return (parsedInfo && parsedInfo[key] !== undefined) ? parsedInfo[key] : defaultVal;
    }

    Layout.fillWidth: true
    cardRadius: Constants.sizeMd
    useBorder: false
    visible: (relRoot.getValue("Provides", "None") !== "None") || (relRoot.getValue("Conflicts With", "None") !== "None") || (relRoot.getValue("Replaces", "None") !== "None")

    ColumnLayout {
        id: relCol

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Constants.sizeSm

        ThemedText {
            text: "Package Relations"
            font.bold: true
            customSize: Constants.sizeMd
            color: Theme.fg
        }

        // Provides
        RowLayout {
            Layout.fillWidth: true
            visible: relRoot.getValue("Provides", "None") !== "None"

            ThemedText {
                text: "Provides"
                color: Theme.muted
                customSize: Constants.sizeSm
                Layout.preferredWidth: 100
            }

            ThemedText {
                text: relRoot.getValue("Provides", "")
                color: Theme.fg
                customSize: Constants.sizeSm
                Layout.fillWidth: true
                wrapMode: Text.Wrap
            }

        }

        // Conflicts With
        RowLayout {
            Layout.fillWidth: true
            visible: relRoot.getValue("Conflicts With", "None") !== "None"

            ThemedText {
                text: "Conflicts"
                color: Theme.muted
                customSize: Constants.sizeSm
                Layout.preferredWidth: 100
            }

            ThemedText {
                text: relRoot.getValue("Conflicts With", "")
                color: Theme.accentComplementary
                customSize: Constants.sizeSm
                Layout.fillWidth: true
                wrapMode: Text.Wrap
            }

        }

        // Replaces
        RowLayout {
            Layout.fillWidth: true
            visible: relRoot.getValue("Replaces", "None") !== "None"

            ThemedText {
                text: "Replaces"
                color: Theme.muted
                customSize: Constants.sizeSm
                Layout.preferredWidth: 100
            }

            ThemedText {
                text: relRoot.getValue("Replaces", "")
                color: Theme.fg
                customSize: Constants.sizeSm
                Layout.fillWidth: true
                wrapMode: Text.Wrap
            }

        }

    }

}
