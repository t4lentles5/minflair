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

    // Card Background
    Rectangle {
        anchors.fill: parent
        radius: Constants.sizeMd
        color: Theme.bgSecondary
        border.color: delegateRoot.isCurrent ? Theme.accent : (delegateHover.hovered ? Theme.border : "transparent")
        border.width: 1

        Behavior on border.color {
            ColorAnimation {
                duration: Constants.animFast
            }

        }

    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Constants.sizeLg
        spacing: Constants.sizeLg

        // Top Row: Icon container + Text + Checkbox
        RowLayout {
            Layout.fillWidth: true
            spacing: Constants.sizeLg

            // Icon container
            Rectangle {
                width: 40
                height: 40
                radius: Constants.sizeSm
                color: Theme.bgTertiary
                Layout.alignment: Qt.AlignTop

                Image {
                    id: pkgIcon

                    anchors.centerIn: parent
                    source: Quickshell.iconPath(delegateRoot.name, true) || ""
                    sourceSize.width: 24
                    sourceSize.height: 24
                    visible: source.toString() !== ""
                }

                SvgIcon {
                    icon: "box"
                    iconSize: 20
                    iconColor: Theme.muted
                    anchors.centerIn: parent
                    visible: !pkgIcon.visible
                    flat: true
                }

            }

            // Name, Repo, Version column
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
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
                        implicitWidth: repoLabel.implicitWidth + 16
                        implicitHeight: repoLabel.implicitHeight + 6
                        radius: 6
                        color: "transparent"
                        border.color: Theme.border
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
                            color: Theme.muted
                        }

                    }

                }

                ThemedText {
                    text: delegateRoot.version
                    customSize: Constants.sizeSm
                    color: Theme.muted
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

            }

            // Checkbox (custom designed)
            Rectangle {
                width: 18
                height: 18
                radius: 4
                color: delegateRoot.isSelected ? Theme.accent : "transparent"
                border.width: delegateRoot.isSelected ? 0 : 2
                border.color: Theme.border
                Layout.alignment: Qt.AlignTop

                SvgIcon {
                    anchors.centerIn: parent
                    icon: "check"
                    iconSize: 12
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
            opacity: 0.9
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
            Layout.fillWidth: true
            Layout.fillHeight: true
            verticalAlignment: Text.AlignTop
        }

        // Footer: Size & More Info
        RowLayout {
            Layout.fillWidth: true
            spacing: Constants.sizeXs

            ThemedText {
                text: delegateRoot.isDetailLoading ? "···" : delegateRoot.pkgSize
                customSize: Constants.sizeSm
                color: Theme.muted
            }

            Item {
                Layout.fillWidth: true
            }

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: moreInfoText.implicitWidth + 24
                height: 28
                radius: Constants.sizeXs
                color: "transparent"
                border.width: 1
                border.color: moreInfoHover.hovered ? Theme.accent : Theme.border

                ThemedText {
                    id: moreInfoText

                    anchors.centerIn: parent
                    text: "Details"
                    customSize: Constants.sizeSm
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
