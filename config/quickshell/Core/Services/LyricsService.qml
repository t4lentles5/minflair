import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.Core
pragma Singleton

Item {
    id: lyricsService

    property bool loading: false
    property bool hasLyrics: false
    property bool isSynced: false
    property var lines: []
    property string plainLyrics: ""
    property int currentLineIndex: -1
    // Internal tracking to prevent duplicate calls
    property string _lastFetchKey: ""
    property var _playerConn

    function _bindPlayer(player) {
        _playerConn.target = player;
        _fetchLyrics();
    }

    function _clearLyrics() {
        loading = false;
        hasLyrics = false;
        isSynced = false;
        lines = [];
        plainLyrics = "";
        currentLineIndex = -1;
        _lastFetchKey = "";
    }

    function _fetchLyrics() {
        let player = MprisService.activePlayer;
        if (!player || !player.trackTitle) {
            _clearLyrics();
            return ;
        }
        let title = player.trackTitle;
        let artist = player.trackArtist || "";
        let album = player.trackAlbum || "";
        let dur = player.length ? Math.floor(player.length) : 0;
        let url = player.trackArtUrl || "";
        let key = title + "|" + artist + "|" + dur;
        if (_lastFetchKey === key)
            return ;

        _lastFetchKey = key;
        loading = true;
        hasLyrics = false;
        let cmd = ["python3", Quickshell.shellDir + "/Scripts/get_lyrics.py", "--title", title, "--artist", artist, "--album", album, "--duration", String(dur), "--file-url", url];
        lyricsProc.command = cmd;
        lyricsProc.running = false;
        lyricsProc.running = true;
    }

    function _updateActiveLine() {
        if (!isSynced || lines.length === 0 || !MprisService.activePlayer)
            return ;

        let posSec = MprisService.activePlayer.position + 0.35;
        let foundIdx = -1;
        for (let i = 0; i < lines.length; i++) {
            if (lines[i].time <= posSec)
                foundIdx = i;
            else
                break;
        }
        if (foundIdx !== currentLineIndex)
            currentLineIndex = foundIdx;

    }

    function seekToLine(index) {
        if (!isSynced || index < 0 || index >= lines.length || !MprisService.activePlayer || !MprisService.activePlayer.canSeek)
            return ;

        MprisService.activePlayer.position = lines[index].time;
        currentLineIndex = index;
    }

    Timer {
        running: MprisService.isPlaying && isSynced
        interval: 50
        repeat: true
        onTriggered: _updateActiveLine()
    }

    Connections {
        function onActivePlayerChanged() {
            if (MprisService.activePlayer)
                _bindPlayer(MprisService.activePlayer);
            else
                _clearLyrics();
        }

        target: MprisService
    }

    Process {
        id: lyricsProc

        stdout: SplitParser {
            onRead: (data) => {
                if (!data)
                    return ;

                try {
                    let res = JSON.parse(data);
                    if (res.success) {
                        lyricsService.isSynced = res.synced;
                        lyricsService.lines = res.lines || [];
                        lyricsService.plainLyrics = res.plainLyrics || "";
                        lyricsService.hasLyrics = (res.lines && res.lines.length > 0) || (res.plainLyrics !== "");
                    } else {
                        lyricsService.hasLyrics = false;
                        lyricsService.isSynced = false;
                        lyricsService.lines = [];
                        lyricsService.plainLyrics = "";
                    }
                } catch (e) {
                    console.log("Lyrics parse error:", e);
                }
                lyricsService.loading = false;
                lyricsService._updateActiveLine();
            }
        }

    }

    _playerConn: Connections {
        function onTrackTitleChanged() {
            _fetchLyrics();
        }

        function onTrackArtistChanged() {
            _fetchLyrics();
        }

        function onLengthChanged() {
            _fetchLyrics();
        }

        function onPositionChanged() {
            _updateActiveLine();
        }

        target: MprisService.activePlayer
        ignoreUnknownSignals: true
    }

}
