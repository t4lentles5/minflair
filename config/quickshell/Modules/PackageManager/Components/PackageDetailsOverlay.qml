import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Core
import qs.Core.Components

Rectangle {
    id: detailsOverlay

    property var managerRoot
    property string pkgName: managerRoot && managerRoot.currentDetailPkg ? managerRoot.currentDetailPkg.name : ""
    property string detailText: managerRoot ? managerRoot.currentDetailText : ""
    property var parsedInfo: {
        let text = detailText;
        let result = {
        };
        if (text === "Loading details..." || text.indexOf("Could not load") !== -1)
            return result;

        let lines = text.split("\n");
        let currentKey = "";
        let currentVal = "";
        for (let i = 0; i < lines.length; i++) {
            let line = lines[i];
            if (line.trim() === "")
                continue;

            if (line.startsWith(" ") && currentKey !== "") {
                currentVal += " " + line.trim();
                result[currentKey] = currentVal;
                continue;
            }
            let idx = line.indexOf(" : ");
            if (idx !== -1) {
                currentKey = line.substring(0, idx).trim();
                currentVal = line.substring(idx + 3).trim();
                result[currentKey] = currentVal;
            }
        }
        return result;
    }
    readonly property bool isInstalled: {
        if (managerRoot && managerRoot.currentDetailPkg && managerRoot.currentDetailPkg.installed !== undefined)
            return managerRoot.currentDetailPkg.installed;

        return parsedInfo["Install Date"] !== undefined || parsedInfo["Install Reason"] !== undefined;
    }
    readonly property bool isSelected: {
        if (!managerRoot || !managerRoot.selectedPackages)
            return false;

        return managerRoot.selectedPackages.indexOf(detailsOverlay.pkgName) !== -1;
    }

    color: Theme.opaqueBg
    opacity: visible ? 1 : 0
    z: 100
    onVisibleChanged: {
        if (visible)
            forceActiveFocus();
        else if (managerRoot && typeof managerRoot.triggerDelayedFocus === "function")
            managerRoot.triggerDelayedFocus();
    }
    Keys.onEscapePressed: {
        detailsOverlay.visible = false;
    }

    MouseArea {
        anchors.fill: parent
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Constants.sizeLg
        spacing: Constants.sizeMd

        // Top Navigation Bar
        RowLayout {
            Layout.fillWidth: true
            spacing: Constants.sizeSm

            Rectangle {
                implicitHeight: Constants.size3Xl
                implicitWidth: backRow.implicitWidth + 20
                radius: Constants.sizeXs
                color: backHover.hovered ? Theme.bgSecondary : "transparent"
                border.width: 1
                border.color: Theme.border

                RowLayout {
                    id: backRow

                    anchors.centerIn: parent
                    spacing: 6

                    SvgIcon {
                        icon: "chevron-left"
                        iconSize: Constants.sizeMd
                        iconColor: backHover.hovered ? Theme.fg : Theme.muted
                        flat: true
                    }

                    ThemedText {
                        text: "Back to Packages"
                        customSize: Constants.sizeSm
                        font.bold: true
                        color: backHover.hovered ? Theme.fg : Theme.muted
                    }

                }

                HoverHandler {
                    id: backHover

                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: detailsOverlay.visible = false
                }

            }

            ThemedText {
                text: (parsedInfo["Repository"] ? parsedInfo["Repository"].toUpperCase() : "PKG") + " / " + detailsOverlay.pkgName
                customSize: Constants.sizeMd
                color: Theme.muted
                font.bold: true
            }

            Item {
                Layout.fillWidth: true
            }

        }

        // Loading or Error State
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: Object.keys(parsedInfo).length === 0

            ColumnLayout {
                anchors.centerIn: parent
                spacing: Constants.sizeMd

                SvgIcon {
                    icon: detailsOverlay.detailText.indexOf("Could not load") !== -1 ? "warning" : "refresh"
                    iconSize: 36
                    iconColor: Theme.muted
                    Layout.alignment: Qt.AlignHCenter
                    flat: true
                }

                ThemedText {
                    text: detailsOverlay.detailText === "Loading details..." ? "Loading package details..." : (detailsOverlay.detailText.indexOf("Could not load") !== -1 ? "Could not load package details" : "")
                    color: Theme.muted
                    customSize: Constants.sizeMd
                    Layout.alignment: Qt.AlignHCenter
                }

            }

        }

        // Main Content (Hero + 2-Column Details)
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            visible: Object.keys(parsedInfo).length > 0
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            contentWidth: availableWidth

            ColumnLayout {
                width: parent.width
                spacing: Constants.sizeLg

                // 1. Hero Card
                PackageDetailsHero {
                    pkgName: detailsOverlay.pkgName
                    parsedInfo: detailsOverlay.parsedInfo
                    isInstalled: detailsOverlay.isInstalled
                    isSelected: detailsOverlay.isSelected
                    managerRoot: detailsOverlay.managerRoot
                }

                // 2. Two-Column Split Layout
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Constants.sizeLg
                    Layout.alignment: Qt.AlignTop

                    // LEFT COLUMN (Main Content)
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        spacing: Constants.sizeLg

                        // Card: About
                        Card {
                            Layout.fillWidth: true
                            cardRadius: Constants.sizeSm
                            useBorder: true
                            borderColor: Theme.border
                            backgroundColor: Theme.bgSecondary
                            contentPadding: Constants.sizeLg

                            ColumnLayout {
                                id: aboutCol

                                anchors.fill: parent
                                spacing: Constants.sizeSm

                                RowLayout {
                                    spacing: Constants.sizeXs

                                    SvgIcon {
                                        icon: "info"
                                        iconSize: Constants.sizeMd
                                        iconColor: Theme.muted
                                        flat: true
                                    }

                                    ThemedText {
                                        text: "ABOUT"
                                        font.bold: true
                                        font.letterSpacing: 0.8
                                        customSize: 10
                                        color: Theme.muted
                                    }

                                }

                                ThemedText {
                                    text: detailsOverlay.parsedInfo["Description"] || "No description provided."
                                    color: Theme.fg
                                    customSize: Constants.sizeSm
                                    wrapMode: Text.Wrap
                                    Layout.fillWidth: true
                                }

                            }

                        }

                        // Card: Dependencies
                        PackageDependenciesCard {
                            parsedInfo: detailsOverlay.parsedInfo
                        }

                        // Card: Package Relations
                        PackageRelationsCard {
                            parsedInfo: detailsOverlay.parsedInfo
                        }

                    }

                    // RIGHT COLUMN (Sidebar Specs & Links)
                    ColumnLayout {
                        Layout.preferredWidth: 320
                        Layout.maximumWidth: 360
                        Layout.alignment: Qt.AlignTop
                        spacing: Constants.sizeLg

                        // Card: Specifications
                        PackageSpecsCard {
                            parsedInfo: detailsOverlay.parsedInfo
                        }

                        // Card: External Resources
                        PackageResourcesCard {
                            parsedInfo: detailsOverlay.parsedInfo
                        }

                    }

                }

            }

        }

    }

    Behavior on opacity {
        NumberAnimation {
            duration: Constants.animFast
        }

    }

}
