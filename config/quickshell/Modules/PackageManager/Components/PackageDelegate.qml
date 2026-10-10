import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Core
import qs.Core.Components

Item {
    id: delegateRoot

    required property int index
    required property string name
    required property string version
    required property string repo
    required property string source
    required property string description
    required property bool installed
    required property bool selected
    property var rootRef
    property var listViewRef
    readonly property bool isCurrent: listViewRef.currentIndex === index && listViewRef.activeFocus
    readonly property bool isSelected: selected
    property bool isDetailLoading: false
    property string pkgSize: ""
    property string pkgInstallDate: ""
    property string pkgReason: ""
    property string pkgLicense: ""

    function loadDetails() {
        isDetailLoading = true;
        pkgSize = "";
        pkgInstallDate = "";
        pkgReason = "";
        pkgLicense = "";
        let cmd = installed ? ["pacman", "-Qi", name] : ["pacman", "-Si", name];
        infoProc.command = cmd;
        infoProc.running = false;
        infoProc.running = true;
    }

    Component.onCompleted: loadDetails()
    width: listViewRef.cellWidth - Constants.sizeSm
    height: listViewRef.cellHeight - Constants.sizeSm

    Process {
        id: infoProc

        onExited: function(code) {
            if (code === 0) {
                let lines = infoOutput.text.split('\n');
                for (let i = 0; i < lines.length; i++) {
                    let line = lines[i];
                    if (line.indexOf("Installed Size") !== -1 || line.indexOf("Download Size") !== -1) {
                        delegateRoot.pkgSize = line.split(":")[1].trim();
                    } else if (line.indexOf("Install Date") !== -1) {
                        let raw = line.split(":", 2)[1].trim();
                        let match = raw.match(/(\d{4}-\d{2}-\d{2})/);
                        delegateRoot.pkgInstallDate = match ? match[1] : raw.split(" ").slice(0, 4).join(" ");
                    } else if (line.indexOf("Install Reason") !== -1) {
                        let r = line.split(":")[1].trim();
                        if (r === "Explicitly installed")
                            delegateRoot.pkgReason = "Explicit";
                        else if (r.indexOf("dependency") !== -1)
                            delegateRoot.pkgReason = "Dependency";
                        else
                            delegateRoot.pkgReason = r;
                    } else if (line.indexOf("Licenses") !== -1) {
                        delegateRoot.pkgLicense = line.split(":")[1].trim();
                    }
                }
            }
            delegateRoot.isDetailLoading = false;
        }

        stdout: StdioCollector {
            id: infoOutput
        }

    }

    // Card Container
    Card {
        id: cardBg

        anchors.fill: parent
        contentPadding: Constants.sizeLg
        cardRadius: Constants.sizeSm
        useBorder: true
        backgroundColor: delegateHover.hovered ? Theme.bgSecondary : Theme.bgTertiary
        borderColor: delegateRoot.isCurrent || delegateRoot.isSelected ? Theme.accent : Theme.border

        ColumnLayout {
            anchors.fill: parent
            spacing: Constants.sizeSm

            // Top Row: Icon container + Text + Checkbox
            RowLayout {
                Layout.fillWidth: true
                spacing: Constants.sizeMd

                // Icon container
                Rectangle {
                    width: 42
                    height: 42
                    radius: Constants.sizeXs
                    color: Theme.bgTertiary
                    border.color: Theme.border
                    border.width: 1
                    Layout.alignment: Qt.AlignTop

                    Image {
                        id: pkgIcon

                        anchors.centerIn: parent
                        source: Quickshell.iconPath(delegateRoot.name, true) || ""
                        sourceSize.width: 26
                        sourceSize.height: 26
                        visible: source.toString() !== ""
                    }

                    SvgIcon {
                        icon: "box"
                        iconSize: 22
                        iconColor: Theme.muted
                        anchors.centerIn: parent
                        visible: !pkgIcon.visible
                        flat: true
                    }

                }

                // Name, Repo, Version column
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3
                    Layout.alignment: Qt.AlignTop

                    RowLayout {
                        Layout.maximumWidth: parent.width
                        spacing: Constants.sizeSm

                        ThemedText {
                            text: delegateRoot.name
                            font.bold: true
                            customSize: Constants.sizeMd
                            color: delegateRoot.isCurrent ? Theme.accent : Theme.fg
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            implicitWidth: repoLabel.implicitWidth + 14
                            implicitHeight: Constants.size2Xl
                            radius: height / 2 + Constants.size2Xs
                            color: delegateRoot.installed ? Theme.bgAccent : Theme.bgTertiary
                            border.color: delegateRoot.installed ? "transparent" : Theme.border
                            border.width: 1

                            ThemedText {
                                id: repoLabel

                                anchors.centerIn: parent
                                text: {
                                    if (delegateRoot.installed)
                                        return "Installed";

                                    let r = (delegateRoot.source === "AUR" ? "aur" : delegateRoot.repo).toLowerCase();
                                    if (r === "aur")
                                        return "AUR";

                                    return delegateRoot.repo.charAt(0).toUpperCase() + delegateRoot.repo.slice(1);
                                }
                                customSize: Constants.sizeXs
                                font.bold: delegateRoot.installed
                                color: delegateRoot.installed ? Theme.accent : Theme.fg
                            }

                        }

                    }

                    ThemedText {
                        text: delegateRoot.version
                        customSize: Constants.sizeSm - 1
                        color: Theme.muted
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                }

                // Checkbox
                Rectangle {
                    width: Constants.size2Xl
                    height: Constants.size2Xl
                    radius: Constants.size2Xs + 2
                    color: delegateRoot.isSelected ? Theme.accent : (delegateHover.hovered ? Theme.border : "transparent")
                    border.width: delegateRoot.isSelected ? 0 : 1.5
                    border.color: delegateRoot.isSelected ? Theme.accent : Theme.border
                    Layout.alignment: Qt.AlignTop

                    SvgIcon {
                        anchors.centerIn: parent
                        icon: "check"
                        iconSize: Constants.sizeSm
                        iconColor: Theme.bg
                        visible: delegateRoot.isSelected
                        flat: true
                    }

                    TapHandler {
                        onTapped: rootRef.toggleSelect(delegateRoot.name)
                    }

                }

            }

            // Description
            ThemedText {
                text: delegateRoot.description
                customSize: Constants.sizeSm
                color: Theme.fg
                opacity: 0.85
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                Layout.fillWidth: true
                Layout.fillHeight: true
                verticalAlignment: Text.AlignTop
            }

            // Footer: Size & Details Button
            RowLayout {
                Layout.fillWidth: true
                spacing: Constants.sizeXs

                ThemedText {
                    text: delegateRoot.isDetailLoading ? "···" : delegateRoot.pkgSize
                    customSize: Constants.sizeSm - 1
                    color: Theme.muted
                }

                Item {
                    Layout.fillWidth: true
                }

                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    width: moreInfoText.implicitWidth + Constants.size2Xl
                    height: Constants.size2Xl
                    radius: Constants.sizeXs
                    color: moreInfoHover.hovered ? Theme.bgTertiary : "transparent"
                    border.width: 1
                    border.color: moreInfoHover.hovered ? Theme.accent : Theme.border

                    ThemedText {
                        id: moreInfoText

                        anchors.centerIn: parent
                        text: "Details"
                        customSize: Constants.sizeSm
                        font.bold: moreInfoHover.hovered
                        color: moreInfoHover.hovered ? Theme.accent : Theme.fg

                        Behavior on color {
                            ColorAnimation {
                                duration: Constants.animFast
                            }

                        }

                    }

                    HoverHandler {
                        id: moreInfoHover

                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        onTapped: rootRef.showPackageDetails(delegateRoot.name, delegateRoot.installed)
                    }

                }

            }

        }

        Behavior on borderColor {
            ColorAnimation {
                duration: Constants.animFast
            }

        }

    }

    HoverHandler {
        id: delegateHover
    }

    TapHandler {
        onTapped: {
            listViewRef.forceActiveFocus();
            if (listViewRef.currentIndex === delegateRoot.index)
                listViewRef.currentIndex = -1;
            else
                listViewRef.currentIndex = delegateRoot.index;
        }
    }

}
