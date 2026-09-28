import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.Core
import qs.Core.Services
pragma Singleton

Item {
    id: root

    property var managedPlayers: []
    property var availablePlayers: []
    property var availablePlayerIds: []
    property var playerDisplayNames: ({
    })
    property var activePlayer: null
    readonly property bool isPlaying: root.activePlayer !== null && (root.activePlayer.playbackState === 1 || root.activePlayer.playbackState === Mpris.Playing || String(root.activePlayer.playbackState).toLowerCase().includes("playing"))
    readonly property string activePlayerName: {
        if (!root.activePlayer)
            return "";

        let id = (root.activePlayer.identity || "").toLowerCase();
        let bus = (root.activePlayer.dbusName || "").toLowerCase();
        if (id.includes("spotify") || bus.includes("spotify"))
            return "Spotify";

        if (id.includes("youtube") || bus.includes("youtube"))
            return "YouTube Music";

        if (id.includes("kew") || bus.includes("kew"))
            return "Kew";

        if (id.includes("vlc") || bus.includes("vlc"))
            return "VLC";

        if (id.includes("mpv") || bus.includes("mpv"))
            return "mpv";

        return root.activePlayer.identity || root.getDisplayName(SettingsService.musicPlayer);
    }

    function toggleShuffle() {
        if (!root.activePlayer)
            return ;

        if (root.activePlayer.shuffleSupported) {
            root.activePlayer.shuffle = !root.activePlayer.shuffle;
        } else {
            let bus = root.activePlayer.dbusName || "";
            let pName = bus.replace("org.mpris.MediaPlayer2.", "");
            if (pName)
                mprisControlProc.command = ["playerctl", "-p", pName, "shuffle", "toggle"];
            else
                mprisControlProc.command = ["playerctl", "shuffle", "toggle"];
            mprisControlProc.running = false;
            mprisControlProc.running = true;
        }
    }

    function cycleLoop() {
        if (!root.activePlayer)
            return ;

        if (root.activePlayer.loopSupported) {
            let curr = root.activePlayer.loopState;
            let nextState = 0;
            // Cycle: None (0) -> Playlist (2) -> Track (1) -> None (0)
            if (curr === 0)
                nextState = 2;
            else if (curr === 2)
                nextState = 1;
            else
                nextState = 0;
            root.activePlayer.loopState = nextState;
        } else {
            let bus = root.activePlayer.dbusName || "";
            let pName = bus.replace("org.mpris.MediaPlayer2.", "");
            let nextArg = "toggle";
            if (pName)
                mprisControlProc.command = ["playerctl", "-p", pName, "loop", nextArg];
            else
                mprisControlProc.command = ["playerctl", "loop", nextArg];
            mprisControlProc.running = false;
            mprisControlProc.running = true;
        }
    }

    function getDisplayName(id) {
        if (!id || id === "none")
            return "None";

        if (id === "custom")
            return "Custom Command";

        if (root.playerDisplayNames && root.playerDisplayNames[id])
            return root.playerDisplayNames[id];

        for (let i = 0; i < root.availablePlayers.length; i++) {
            if (root.availablePlayers[i].id === id)
                return root.availablePlayers[i].name;

        }
        return id.split('-').map((word) => {
            return word.charAt(0).toUpperCase() + word.slice(1);
        }).join(' ');
    }

    function getPlayerById(id) {
        for (let i = 0; i < root.availablePlayers.length; i++) {
            if (root.availablePlayers[i].id === id)
                return root.availablePlayers[i];

        }
        return null;
    }

    function matchesConfiguredPlayer(p) {
        if (!p)
            return false;

        let pref = (SettingsService.musicPlayer || "").toLowerCase().trim();
        if (!pref || pref === "none")
            return false;

        let id = (p.identity || "").toLowerCase();
        let desktop = (p.desktopEntry || "").toLowerCase();
        let bus = (p.dbusName || "").toLowerCase();
        if (pref === "custom") {
            let cmd = (SettingsService.musicPlayerCommand || "").toLowerCase().trim();
            if (!cmd)
                return false;

            let bin = cmd.split(" ")[0].replace(/^.*\//, '');
            if (!bin || bin === "kitty" || bin === "sh" || bin === "bash") {
                let parts = cmd.split(" ");
                for (let k = 1; k < parts.length; k++) {
                    if (!parts[k].startsWith("-")) {
                        bin = parts[k].replace(/^.*\//, '');
                        break;
                    }
                }
            }
            return bin !== "" && (id.includes(bin) || desktop.includes(bin) || bus.includes(bin));
        }
        if (pref === "youtube-music" || pref === "youtube")
            return id.includes("youtube") || desktop.includes("youtube") || bus.includes("youtube");

        if (pref === "spotify")
            return id.includes("spotify") || desktop.includes("spotify") || bus.includes("spotify");

        if (pref === "kew")
            return id.includes("kew") || desktop.includes("kew") || bus.includes("kew");

        if (pref === "vlc")
            return id.includes("vlc") || desktop.includes("vlc") || bus.includes("vlc");

        if (pref === "mpv")
            return id.includes("mpv") || desktop.includes("mpv") || bus.includes("mpv");

        let playerObj = getPlayerById(pref);
        if (playerObj) {
            let targetDesktop = (playerObj.desktopEntry || "").toLowerCase();
            let targetName = (playerObj.name || "").toLowerCase();
            let targetId = (playerObj.id || "").toLowerCase();
            let targetBin = (playerObj.exec || "").toLowerCase().split(" ")[0].replace(/^.*\//, '');
            if (targetDesktop && desktop !== "" && (desktop === targetDesktop || desktop.includes(targetDesktop) || targetDesktop.includes(desktop)))
                return true;

            if (targetId && (id.includes(targetId) || (desktop !== "" && desktop.includes(targetId)) || bus.includes(targetId)))
                return true;

            if (targetName && (id.includes(targetName) || (id !== "" && targetName.includes(id))))
                return true;

            if (targetBin && (id.includes(targetBin) || (desktop !== "" && desktop.includes(targetBin)) || bus.includes(targetBin)))
                return true;

        }
        return (pref !== "" && id.includes(pref)) || (pref !== "" && desktop !== "" && desktop.includes(pref)) || (pref !== "" && bus.includes(pref));
    }

    function getPlayerScore(p) {
        if (!p)
            return -100;

        let score = 0;
        let bus = (p.dbusName || "").toLowerCase();
        // Strongly prefer dedicated app MPRIS services over generic browser wrappers
        if (bus.includes("chromium") || bus.includes("chrome") || bus.includes("brave"))
            score -= 10;

        if (p.shuffleSupported)
            score += 5;

        if (p.loopSupported)
            score += 5;

        return score;
    }

    function updatePlayer() {
        let players = managedPlayers;
        let matchingPlaying = null;
        let matchingPaused = null;
        for (let i = 0; i < players.length; i++) {
            let p = players[i];
            if (!p)
                continue;

            if (matchesConfiguredPlayer(p)) {
                let active = p.playbackState === 1 || p.playbackState === Mpris.Playing || String(p.playbackState).toLowerCase().includes("playing");
                if (active) {
                    if (!matchingPlaying || getPlayerScore(p) > getPlayerScore(matchingPlaying))
                        matchingPlaying = p;

                } else {
                    if (!matchingPaused || getPlayerScore(p) > getPlayerScore(matchingPaused))
                        matchingPaused = p;

                }
            }
        }
        let chosen = matchingPlaying || matchingPaused || null;
        if (root.activePlayer !== chosen)
            root.activePlayer = chosen;

    }

    function registerPlayer(p) {
        let list = managedPlayers;
        if (list.indexOf(p) === -1) {
            list.push(p);
            managedPlayers = list;
            updatePlayer();
        }
    }

    function unregisterPlayer(p) {
        let list = managedPlayers, idx = list.indexOf(p);
        if (idx !== -1) {
            list.splice(idx, 1);
            managedPlayers = list;
            updatePlayer();
        }
    }

    function formatTime(s) {
        if (isNaN(s) || s < 0)
            return "0:00";

        let m = Math.floor(s / 60), sec = Math.floor(s % 60);
        return m + ":" + (sec < 10 ? "0" : "") + sec;
    }

    function launchPlayer() {
        if (!SettingsService.musicPlayer || SettingsService.musicPlayer === "" || SettingsService.musicPlayer === "none")
            return ;

        let playerObj = getPlayerById(SettingsService.musicPlayer);
        let cmd = "";
        let isTerminal = false;
        if (SettingsService.musicPlayer === "custom") {
            cmd = SettingsService.musicPlayerCommand;
        } else if (playerObj) {
            cmd = playerObj.exec;
            isTerminal = playerObj.terminal;
        } else {
            cmd = SettingsService.musicPlayerCommand || SettingsService.musicPlayer;
        }
        if (!cmd || cmd.trim() === "")
            return ;

        let parts = cmd.trim().split(" ").filter((x) => {
            return x !== "";
        });
        if (isTerminal && parts[0] !== "kitty" && parts[0] !== "alacritty" && parts[0] !== "foot")
            parts = ["kitty", "-e"].concat(parts);

        launcherProc.command = parts;
        launcherProc.running = false;
        launcherProc.startDetached();
    }

    function killConfiguredPlayer() {
        if (!SettingsService.musicPlayer || SettingsService.musicPlayer === "" || SettingsService.musicPlayer === "none")
            return ;

        let cmd = SettingsService.musicPlayerCommand;
        if (!cmd || cmd.trim() === "")
            cmd = SettingsService.musicPlayer;

        if (!cmd || cmd.trim() === "")
            return ;

        let parts = cmd.trim().split(" ");
        let binary = parts[0];
        if (binary === "kitty" || binary === "sh" || binary === "bash") {
            for (let i = 1; i < parts.length; i++) {
                if (!parts[i].startsWith("-")) {
                    binary = parts[i];
                    break;
                }
            }
        }
        binary = binary.replace(/^.*\//, '');
        if (binary) {
            killProc.command = ["killall", "-9", binary];
            killProc.running = false;
            killProc.running = true;
        }
    }

    Process {
        id: playerScannerProc

        command: ["python3", Quickshell.shellDir + "/Modules/MusicPopup/scripts/get_music_players.py"]
        Component.onCompleted: running = true
        onExited: (exitCode) => {
            if (exitCode === 0) {
                try {
                    let parsed = JSON.parse(playerScannerOutput.text.trim());
                    if (Array.isArray(parsed)) {
                        root.availablePlayers = parsed;
                        let ids = [];
                        let names = {
                        };
                        for (let i = 0; i < parsed.length; i++) {
                            let p = parsed[i];
                            ids.push(p.id);
                            names[p.id] = p.name;
                        }
                        root.availablePlayerIds = ids;
                        root.playerDisplayNames = names;
                        root.updatePlayer();
                    }
                } catch (e) {
                    console.error("Error parsing music players: " + e);
                }
            }
        }

        stdout: StdioCollector {
            id: playerScannerOutput
        }

    }

    Process {
        id: launcherProc
    }

    Process {
        id: killProc
    }

    Process {
        id: mprisControlProc
    }

    Connections {
        function onMusicPlayerChanged() {
            root.updatePlayer();
        }

        function onMusicPlayerCommandChanged() {
            root.updatePlayer();
        }

        target: SettingsService
    }

    Timer {
        running: root.isPlaying
        interval: 1000
        repeat: true
        onTriggered: {
            if (root.activePlayer)
                root.activePlayer.positionChanged();

        }
    }

    Instantiator {
        model: Mpris.players

        delegate: QtObject {
            property var p: modelData
            property var state: p.playbackState
            property var title: p.trackTitle

            onStateChanged: root.updatePlayer()
            onTitleChanged: root.updatePlayer()
            Component.onCompleted: root.registerPlayer(p)
            Component.onDestruction: root.unregisterPlayer(p)
        }

    }

}
