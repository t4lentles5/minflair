import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Core
import qs.Core.Components
import qs.Core.Services

Card {
    id: root

    readonly property string pacmanUpdates: UpdateService.pacmanUpdatesCount
    readonly property string aurUpdates: UpdateService.aurUpdatesCount
    property bool hasUpdates: (parseInt(pacmanUpdates) > 0 || parseInt(aurUpdates) > 0)
    readonly property bool isChecking: UpdateService.isCheckingUpdates
    readonly property bool isUpdating: UpdateService.isSystemUpdating

    function runUpdate() {
        SettingsService.packageManagerMode = "update";
        AppState.openPopup("packagemanager");
    }

    contentPadding: Constants.sizeMd
    implicitHeight: contentCol.implicitHeight + root.contentPadding * 2

    ColumnLayout {
        id: contentCol

        anchors.fill: parent
        spacing: Constants.sizeXs

        RowLayout {
            Layout.fillWidth: true
            spacing: Constants.sizeSm

            ThemedText {
                text: "System Updates"
                customSize: Constants.sizeMd
                font.bold: true
                color: Theme.fg
            }

            Item {
                Layout.fillWidth: true
            }

            Rectangle {
                visible: root.hasUpdates && !root.isUpdating && !root.isChecking
                color: Theme.bgSecondary
                radius: height / 2
                implicitWidth: updateCountText.implicitWidth + 12
                implicitHeight: 18

                ThemedText {
                    id: updateCountText

                    anchors.centerIn: parent
                    text: {
                        let total = (parseInt(root.pacmanUpdates) || 0) + (parseInt(root.aurUpdates) || 0);
                        return total + " NEW";
                    }
                    customSize: Constants.sizeXs + 1
                    font.bold: true
                    color: Theme.accent
                }

            }

        }

        Divider {
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Constants.sizeMd

            RowLayout {
                spacing: Constants.sizeSm
                Layout.fillWidth: true

                SvgIcon {
                    id: statusIcon

                    icon: {
                        if (root.isUpdating || root.isChecking)
                            return "reload";

                        return root.hasUpdates ? "update" : "check";
                    }
                    flat: true
                    iconColor: {
                        if (root.isUpdating)
                            return Theme.accent;

                        if (root.isChecking)
                            return Theme.muted;

                        return Theme.accent;
                    }

                    RotationAnimation on rotation {
                        from: 0
                        to: 360
                        duration: 1000
                        loops: Animation.Infinite
                        running: root.isUpdating || root.isChecking
                        onRunningChanged: {
                            if (!running)
                                statusIcon.rotation = 0;

                        }
                    }

                }

                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true

                    ThemedText {
                        text: {
                            if (root.isUpdating)
                                return "Updating system...";

                            if (root.isChecking)
                                return "Checking updates...";

                            if (root.pacmanUpdates === "..." || root.aurUpdates === "...")
                                return "Checking updates...";

                            let total = (parseInt(root.pacmanUpdates) || 0) + (parseInt(root.aurUpdates) || 0);
                            return total > 0 ? total + " packages pending" : "System up to date";
                        }
                        font.bold: true
                        color: Theme.fg
                    }

                    ThemedText {
                        text: {
                            if (root.isUpdating || root.isChecking || root.pacmanUpdates === "...")
                                return "Please wait";

                            let total = (parseInt(root.pacmanUpdates) || 0) + (parseInt(root.aurUpdates) || 0);
                            if (total > 0)
                                return "Pacman: " + root.pacmanUpdates + " | AUR: " + root.aurUpdates;

                            return "All packages are currently up to date";
                        }
                        customSize: Constants.sizeXs + 1
                        color: Theme.muted
                    }

                }

            }

            Item {
                Layout.fillWidth: true
            }

            ThemedButton {
                id: updateButton

                text: root.hasUpdates && !root.isUpdating ? "Update" : "Check"
                onClicked: {
                    if (root.hasUpdates && !root.isUpdating)
                        root.runUpdate();
                    else
                        UpdateService.checkUpdates();
                }

                SequentialAnimation on scale {
                    running: root.hasUpdates && !root.isUpdating
                    loops: Animation.Infinite

                    PropertyAnimation {
                        to: 1.04
                        duration: 800
                        easing.type: Easing.InOutQuad
                    }

                    PropertyAnimation {
                        to: 1
                        duration: 800
                        easing.type: Easing.InOutQuad
                    }

                }

            }

        }

    }

}
