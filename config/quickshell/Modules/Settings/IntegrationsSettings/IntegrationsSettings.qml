import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Settings.Components

AppContainer {
    id: root

    AppGroup {
        title: "Default Applications"
        icon: "star"

        ThemedSelect {
            id: playerSelect

            function syncIndex() {
                let current = SettingsService.musicPlayer;
                if (!current || current === "")
                    current = "none";

                let idx = model.indexOf(current);
                playerSelect.currentIndex = idx !== -1 ? idx : 0;
            }

            label: "Default Music Player"
            description: "Used by media widgets"
            model: {
                let players = ["none"];
                for (let i = 0; i < MprisService.availablePlayers.length; i++) {
                    let p = MprisService.availablePlayers[i];
                    if (players.indexOf(p.id) === -1)
                        players.push(p.id);

                }
                if (SettingsService.musicPlayer && players.indexOf(SettingsService.musicPlayer) === -1 && SettingsService.musicPlayer !== "custom" && SettingsService.musicPlayer !== "none" && SettingsService.musicPlayer !== "")
                    players.push(SettingsService.musicPlayer);

                if (players.indexOf("custom") === -1)
                    players.push("custom");

                return players;
            }
            Component.onCompleted: syncIndex()
            onModelChanged: syncIndex()
            onActivated: (index) => {
                let player = model[index];
                if (player === "none") {
                    SettingsService.musicPlayer = "none";
                    SettingsService.musicPlayerCommand = "";
                } else {
                    SettingsService.musicPlayer = player;
                    if (player !== "custom") {
                        let playerObj = MprisService.getPlayerById(player);
                        if (playerObj)
                            SettingsService.musicPlayerCommand = playerObj.exec;
                        else
                            SettingsService.musicPlayerCommand = player;
                    }
                }
            }
            textMap: {
                let map = {
                    "none": "None"
                };
                for (let i = 0; i < MprisService.availablePlayers.length; i++) {
                    let p = MprisService.availablePlayers[i];
                    map[p.id] = p.name;
                }
                map["custom"] = "Custom Command";
                return map;
            }
            iconMap: {
                "spotify": "spotify",
                "youtube-music": "youtube",
                "mpd": "music",
                "kew": "music",
                "vlc": "music",
                "mpv": "music",
                "custom": "terminal"
            }

            Connections {
                function onMusicPlayerChanged() {
                    playerSelect.syncIndex();
                }

                target: SettingsService
            }

            Connections {
                function onAvailablePlayersChanged() {
                    playerSelect.syncIndex();
                }

                target: MprisService
            }

        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Constants.sizeMd
            visible: SettingsService.musicPlayer === "custom"

            ThemedTextField {
                Layout.fillWidth: true
                placeholderText: "Command to launch music player..."
                text: SettingsService.musicPlayerCommand
                onEditingFinished: {
                    SettingsService.musicPlayerCommand = text;
                }
            }

        }

    }

    AppGroup {
        title: "Quotes"
        icon: "quote"

        ThemedSelect {
            label: "Quote Category"
            description: "Used by quote widget"
            model: QuoteService.categories
            currentIndex: {
                let idx = model.indexOf(SettingsService.quoteCategory);
                return idx !== -1 ? idx : 0;
            }
            onActivated: (index) => {
                SettingsService.quoteCategory = model[index];
            }
        }

    }

    AppGroup {
        title: "GitHub Integration"
        icon: "github"
        showDividers: false

        ColumnLayout {
            Layout.fillWidth: true

            ThemedText {
                text: "GitHub Username"
            }

            ThemedTextField {
                Layout.fillWidth: true
                placeholderText: "octocat"
                text: SettingsService.githubUsername
                onEditingFinished: {
                    SettingsService.githubUsername = text;
                }
            }

        }

        ColumnLayout {
            Layout.fillWidth: true

            ThemedText {
                text: "GitHub Personal Access Token"
            }

            ThemedTextField {
                Layout.fillWidth: true
                placeholderText: "ghp_xxxxxxxxxxxxxxxxxxxx"
                isPassword: true
                text: SettingsService.githubToken
                onEditingFinished: {
                    SettingsService.githubToken = text;
                }
            }

        }

    }

}
