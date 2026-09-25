import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Core
import qs.Core.Components

Card {
    id: depsRoot

    property var parsedInfo: ({
    })

    function getValue(key, defaultVal) {
        return (parsedInfo && parsedInfo[key] !== undefined) ? parsedInfo[key] : defaultVal;
    }

    Layout.fillWidth: true
    cardRadius: Constants.sizeMd
    useBorder: false

    ColumnLayout {
        id: depsCol

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Constants.sizeMd

        ThemedText {
            text: "Dependencies"
            font.bold: true
            customSize: Constants.sizeMd
            color: Theme.fg
        }

        // Depends On (Runtime)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Constants.sizeSm
            visible: depsRoot.getValue("Depends On", "None") !== "None"

            ThemedText {
                text: "Required"
                customSize: Constants.sizeSm
                color: Theme.fg
                font.bold: true
            }

            Flow {
                Layout.fillWidth: true
                spacing: Constants.sizeXs

                Repeater {
                    model: depsRoot.getValue("Depends On", "").split(/\s+/).filter((item) => {
                        return item.trim() !== "" && item !== "None";
                    })

                    delegate: Rectangle {
                        implicitWidth: depRow.implicitWidth + Constants.sizeSm * 2
                        implicitHeight: depRow.implicitHeight + Constants.sizeXs * 2
                        radius: Constants.sizeXs
                        color: Theme.bgTertiary
                        border.width: 1
                        border.color: Theme.border

                        RowLayout {
                            id: depRow

                            anchors.centerIn: parent
                            spacing: Constants.sizeXs

                            SvgIcon {
                                icon: "box"
                                iconSize: 12
                                iconColor: Theme.muted
                                flat: true
                            }

                            ThemedText {
                                text: modelData
                                customSize: Constants.sizeSm
                                color: Theme.fg
                            }

                        }

                    }

                }

            }

        }

        // Make Deps (Build)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Constants.sizeSm
            visible: depsRoot.getValue("Make Deps", "None") !== "None"

            ThemedText {
                text: "Build (Make)"
                customSize: Constants.sizeSm
                color: Theme.fg
                font.bold: true
            }

            Flow {
                Layout.fillWidth: true
                spacing: Constants.sizeXs

                Repeater {
                    model: depsRoot.getValue("Make Deps", "").split(/\s+/).filter((item) => {
                        return item.trim() !== "" && item !== "None";
                    })

                    delegate: Rectangle {
                        implicitWidth: makeRow.implicitWidth + Constants.sizeSm * 2
                        implicitHeight: makeRow.implicitHeight + Constants.sizeXs * 2
                        radius: Constants.sizeXs
                        color: Theme.bgTertiary
                        border.width: 1
                        border.color: Theme.border

                        RowLayout {
                            id: makeRow

                            anchors.centerIn: parent
                            spacing: Constants.sizeXs

                            ThemedText {
                                text: modelData
                                customSize: Constants.sizeSm
                                color: Theme.muted
                            }

                        }

                    }

                }

            }

        }

        // Optional Deps
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Constants.sizeSm
            visible: depsRoot.getValue("Optional Deps", "None") !== "None"

            ThemedText {
                text: "Optional"
                customSize: Constants.sizeSm
                color: Theme.fg
                font.bold: true
            }

            Flow {
                Layout.fillWidth: true
                spacing: Constants.sizeXs

                Repeater {
                    model: depsRoot.getValue("Optional Deps", "").split(/\s+/).filter((item) => {
                        return item.trim() !== "" && item !== "None";
                    })

                    delegate: Rectangle {
                        implicitWidth: optRow.implicitWidth + Constants.sizeSm * 2
                        implicitHeight: optRow.implicitHeight + Constants.sizeXs * 2
                        radius: Constants.sizeXs
                        color: Theme.bgTertiary
                        border.width: 1
                        border.color: Theme.border

                        RowLayout {
                            id: optRow

                            anchors.centerIn: parent
                            spacing: Constants.sizeXs

                            ThemedText {
                                text: modelData
                                customSize: Constants.sizeSm
                                color: Theme.muted
                            }

                        }

                    }

                }

            }

        }

        // Fallback when no dependencies
        ThemedText {
            text: "No dependencies required"
            color: Theme.muted
            customSize: Constants.sizeSm
            visible: depsRoot.getValue("Depends On", "None") === "None" && depsRoot.getValue("Make Deps", "None") === "None" && depsRoot.getValue("Optional Deps", "None") === "None"
        }

    }

}
