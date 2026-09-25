import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Core
import qs.Core.Components
import qs.Core.Services

Card {
    id: root

    clip: true
    contentPadding: Constants.sizeMd
    implicitWidth: 280
    implicitHeight: (GithubService.username !== "" ? profileLayout.implicitHeight : errorLayout.implicitHeight) + root.contentPadding * 2

    ColumnLayout {
        id: profileLayout

        anchors.fill: parent
        spacing: Constants.sizeSm
        visible: GithubService.username !== ""

        RowLayout {
            Layout.fillWidth: true
            spacing: Constants.sizeMd

            TapHandler {
                onTapped: Qt.openUrlExternally("https://github.com/" + GithubService.username)
            }

            HoverHandler {
                cursorShape: Qt.PointingHandCursor
            }

            Item {
                id: avatarWrapper

                width: 54
                height: 54
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                    id: gradientRing

                    anchors.fill: parent
                    radius: width / 2
                    scale: avatarHover.hovered ? 1.06 : 1

                    gradient: Gradient {
                        GradientStop {
                            position: 0
                            color: Theme.accent
                        }

                        GradientStop {
                            position: 1
                            color: Theme.accentComplementary
                        }

                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: Constants.animFast
                            easing.type: Easing.OutQuad
                        }

                    }

                    RotationAnimation on rotation {
                        from: 0
                        to: 360
                        duration: 800
                        loops: Animation.Infinite
                        running: GithubService.isFetching
                        onRunningChanged: {
                            if (!running)
                                gradientRing.rotation = 0;

                        }
                    }

                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 50
                    height: 50
                    radius: width / 2
                    color: Theme.bg
                }

                Item {
                    id: avatarContainer

                    anchors.centerIn: parent
                    width: 44
                    height: 44

                    Image {
                        id: userImage

                        anchors.fill: parent
                        source: (GithubService.avatarUrl || GithubService.username) ? (GithubService.avatarUrl || "https://github.com/identicons/" + GithubService.username + ".png") : ""
                        fillMode: Image.PreserveAspectCrop
                        sourceSize: Qt.size(88, 88)
                        mipmap: true
                        visible: false
                        antialiasing: true
                    }

                    Rectangle {
                        id: mask

                        anchors.fill: parent
                        radius: width / 2
                        visible: false
                        antialiasing: true
                    }

                    OpacityMask {
                        anchors.fill: parent
                        source: userImage
                        maskSource: mask
                        visible: userImage.status === Image.Ready
                    }

                }

                HoverHandler {
                    id: avatarHover
                }

            }

            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter

                ThemedText {
                    text: GithubService.fullName || GithubService.username
                    customSize: Constants.sizeMd
                    font.bold: true
                    color: Theme.fg
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                ThemedText {
                    text: "@" + GithubService.username
                    color: Theme.muted
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

            }

        }

        ThemedText {
            visible: GithubService.bio !== ""
            text: GithubService.bio
            color: Theme.fg
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            maximumLineCount: 2
            elide: Text.ElideRight

            font {
                italic: true
            }

        }

        Divider {
        }

        ColumnLayout {
            id: statsLayout

            Layout.fillWidth: true
            spacing: 4

            InfoRow {
                visible: GithubService.hasToken
                icon: "commit"
                label: "Total Commits"
                value: String(GithubService.totalCommits)
            }

            InfoRow {
                icon: "star"
                label: "Total Stars"
                value: String(GithubService.totalStars)
            }

            InfoRow {
                icon: "code"
                label: "Repositories"
                value: String(GithubService.publicRepos + (GithubService.hasToken ? GithubService.privateRepos : 0))
            }

            InfoRow {
                icon: "fork"
                label: "Total Forks"
                value: String(GithubService.totalForks)
            }

        }

        Card {
            Layout.fillWidth: true
            backgroundColor: Theme.bgSecondary
            contentPadding: Constants.sizeSm
            visible: GithubService.topRepoName !== "..." && GithubService.topRepoName !== "None"
            scale: repoHover.hovered ? 1.02 : 1
            radius: Constants.sizeSm
            useBorder: false

            TapHandler {
                onTapped: Qt.openUrlExternally("https://github.com/" + GithubService.username + "/" + GithubService.topRepoName)
            }

            HoverHandler {
                id: repoHover

                cursorShape: Qt.PointingHandCursor
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Constants.sizeXs

                    SvgIcon {
                        icon: "star-filled"
                        flat: true
                        iconColor: Theme.accent
                        iconSize: Constants.sizeSm + 2
                    }

                    ThemedText {
                        text: GithubService.topRepoName.replace(/^.*\//, "")
                        font.bold: true
                        color: Theme.fg
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                }

                ThemedText {
                    visible: GithubService.topRepoDesc !== ""
                    text: GithubService.topRepoDesc
                    customSize: Constants.sizeXs + 2
                    color: Theme.muted
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 2
                    spacing: Constants.sizeMd

                    RowLayout {
                        spacing: 4
                        visible: GithubService.topRepoLang !== ""

                        Rectangle {
                            width: 6
                            height: 6
                            radius: 3
                            color: Theme.accent
                        }

                        ThemedText {
                            text: GithubService.topRepoLang
                            customSize: Constants.sizeXs + 2
                            color: Theme.muted
                        }

                    }

                    RowLayout {
                        spacing: 4
                        visible: GithubService.topRepoStars > 0

                        SvgIcon {
                            icon: "star"
                            flat: true
                            iconColor: Theme.accent
                            iconSize: Constants.sizeXs + 2
                        }

                        ThemedText {
                            text: String(GithubService.topRepoStars)
                            customSize: Constants.sizeXs + 2
                            color: Theme.muted
                        }

                    }

                    RowLayout {
                        spacing: 4
                        visible: GithubService.topRepoForks > 0

                        SvgIcon {
                            icon: "fork"
                            flat: true
                            iconColor: Theme.accent
                            iconSize: Constants.sizeXs + 2
                        }

                        ThemedText {
                            text: String(GithubService.topRepoForks)
                            customSize: Constants.sizeXs + 2
                            color: Theme.muted
                        }

                    }

                }

            }

            Behavior on scale {
                NumberAnimation {
                    duration: Constants.animFast
                    easing.type: Easing.OutQuad
                }

            }

        }

    }

    ColumnLayout {
        id: errorLayout

        anchors.fill: parent
        anchors.margins: Constants.sizeLg
        visible: GithubService.username === ""
        spacing: Constants.sizeSm

        Item {
            Layout.fillHeight: true
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 64
            height: 64
            radius: width / 2
            color: Theme.bgSecondary

            SvgIcon {
                anchors.centerIn: parent
                icon: "github"
                iconSize: Constants.size4Xl
                flat: true
                iconColor: Theme.accent
            }

        }

        Item {
            Layout.preferredHeight: Constants.sizeXs
        }

        ThemedText {
            text: "Username Required"
            color: Theme.fg
            customSize: Constants.sizeMd
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        ThemedText {
            text: "Configure your GitHub username in settings to view your statistics."
            color: Theme.muted
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
        }

        Item {
            Layout.preferredHeight: Constants.sizeXs
        }

        ThemedButton {
            text: "Configure"
            Layout.alignment: Qt.AlignHCenter
            onClicked: {
                AppState.pendingSettingsTab = 4;
                AppState.openPopup("minflair_settings");
            }
        }

        Item {
            Layout.fillHeight: true
        }

    }

}
