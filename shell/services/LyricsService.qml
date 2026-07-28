pragma Singleton
import QtQuick
import Quickshell
import qs.services

// Fetches synced lyrics from LRCLIB (https://lrclib.net — free, no API
// key) whenever the currently-playing track changes, and exposes which
// line should be showing right now based on MediaService.position.
// Player-agnostic — anything consuming MediaService can use this, not
// just the wallpaper lyrics overlay (WallpaperLyricsOverlay.qml gates
// visibility to Spotify-only itself).
Singleton {
    id: root

    property var lines: []              // [{time: <seconds>, text: "..."}]
    property bool loading: false
    property bool notFound: false
    readonly property bool hasLyrics: lines.length > 0

    property string _fetchedKey: ""     // "artist::title" — avoids refetching the same track repeatedly

    // MPRIS position/length units are inconsistent across players —
    // same defensive heuristic Media.qml's formatTime() already uses
    // (length > 10000 implies microseconds, otherwise seconds).
    function _toSeconds(raw, refLength) {
        return refLength > 10000 ? raw / 1000000 : raw;
    }

    readonly property real positionSeconds: _toSeconds(MediaService.position, MediaService.length)

    // Index of the line that should be showing right now (the last
    // one whose timestamp has already passed), -1 if none yet/no lyrics.
    readonly property int currentIndex: {
        if (lines.length === 0)
            return -1;
        let idx = -1;
        for (let i = 0; i < lines.length; i++) {
            if (lines[i].time <= root.positionSeconds)
                idx = i;
            else
                break;
        }
        return idx;
    }

    Connections {
        target: MediaService
        function onTitleChanged() {
            root._maybeFetch();
        }
        function onArtistChanged() {
            root._maybeFetch();
        }
    }

    Component.onCompleted: _maybeFetch()

    function _maybeFetch() {
        if (!MediaService.hasPlayer || MediaService.title === "" || MediaService.title === "No media playing") {
            lines = [];
            notFound = false;
            _fetchedKey = "";
            return;
        }
        const key = `${MediaService.artist}::${MediaService.title}`;
        if (key === _fetchedKey)
            return;
        _fetchedKey = key;
        _fetch(MediaService.artist, MediaService.title, _toSeconds(MediaService.length, MediaService.length));
    }

    function _fetch(artist, title, durationSeconds) {
        loading = true;
        notFound = false;
        lines = [];

        const xhr = new XMLHttpRequest();
        const url = "https://lrclib.net/api/get?" + "artist_name=" + encodeURIComponent(artist) + "&track_name=" + encodeURIComponent(title) + "&duration=" + Math.round(durationSeconds);

        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            loading = false;
            if (xhr.status !== 200) {
                notFound = true;
                return;
            }
            try {
                const data = JSON.parse(xhr.responseText);
                if (data.syncedLyrics) {
                    lines = _parseLrc(data.syncedLyrics);
                } else {
                    notFound = true;
                }
            } catch (e) {
                console.warn("LyricsService: failed to parse response:", e);
                notFound = true;
            }
        };
        xhr.onerror = () => {
            loading = false;
            notFound = true;
        };
        xhr.open("GET", url, true);
        xhr.send();
    }

    function _parseLrc(text) {
        const result = [];
        const lineRe = /^\[(\d+):(\d+(?:\.\d+)?)\](.*)$/;
        const rawLines = text.split("\n");
        for (const raw of rawLines) {
            const m = raw.match(lineRe);
            if (!m)
                continue;
            const minutes = parseInt(m[1], 10);
            const seconds = parseFloat(m[2]);
            const lineText = m[3].trim();
            if (lineText === "")
                continue;
            result.push({
                time: minutes * 60 + seconds,
                text: lineText
            });
        }
        result.sort((a, b) => a.time - b.time);
        return result;
    }
}
