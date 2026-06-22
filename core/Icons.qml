pragma Singleton
import QtQuick

QtObject {
    readonly property var appMap: {
        "firefox": "󰈹",
        "microsoft-edge": "󰇩",
        "discord": "",
        "vesktop": "",
        "org.kde.dolphin": "",
        "plex": "󰚺",
        "steam": "",
        "spotify": "󰓇",
        "spotube": "󰓇",
        "ristretto": "󰋩",
        "obsidian": "󱓧",
        "google-chrome": "",
        "brave-browser": "󰖟",
        "chromium": "",
        "opera": "",
        "vivaldi": "󰖟",
        "waterfox": "󰖟",
        "zen": "󰖟",
        "thorium": "󰖟",
        "tor-browser": "",
        "floorp": "󰈹",
        "gnome-terminal": "",
        "kitty": "󰄛",
        "konsole": "",
        "alacritty": "",
        "wezterm": "",
        "foot": "󰽒",
        "tilix": "",
        "xterm": "",
        "urxvt": "",
        "st": "",
        "com.mitchellh.ghostty": "󰊠",
        "code": "󰨞",
        "code-oss": "󰨞",
        "sublime-text": "",
        "atom": "",
        "android-studio": "󰀴",
        "intellij-idea": "",
        "pycharm": "󱃖",
        "webstorm": "󱃖",
        "phpstorm": "󱃖",
        "eclipse": "",
        "netbeans": "",
        "docker": "",
        "vim": "",
        "neovim": "",
        "neovide": "",
        "emacs": "",
        "slack": "󰒱",
        "telegram-desktop": "",
        "org.telegram.desktop": "",
        "whatsapp": "󰖣",
        "teams": "󰊻",
        "skype": "󰒯",
        "thunderbird": "",
        "nautilus": "󰝰",
        "thunar": "󰝰",
        "pcmanfm": "󰝰",
        "nemo": "󰝰",
        "ranger": "󰝰",
        "doublecmd": "󰝰",
        "krusader": "󰝰",
        "vlc": "󰕼",
        "mpv": "",
        "rhythmbox": "󰓃",
        "gimp": "",
        "inkscape": "",
        "krita": "",
        "blender": "󰂫",
        "kdenlive": "",
        "lutris": "󰺵",
        "heroic": "󰺵",
        "minecraft": "󰍳",
        "csgo": "󰺵",
        "dota2": "󰺵",
        "evernote": "",
        "sioyek": "",
        "dropbox": "󰇣",
        "desktop": "󰇄"
    }
    readonly property string fallback: "󰣆"
    readonly property var weatherFallback: ({
            icon: "󰖐",
            color: "#a6adc8"
        })
    readonly property var weatherMap: {
        "0": {
            icon: "󰖙",
            color: Theme.color3
        },
        "1": {
            icon: "󰖙",
            color: Theme.color3
        },
        "2": {
            icon: "󰖕",
            color: Theme.color7
        },
        "3": {
            icon: "󰖐",
            color: Theme.color7
        },
        "45": {
            icon: "󰖐",
            color: Theme.color8
        },
        "48": {
            icon: "󰖐",
            color: Theme.color8
        },
        "51": {
            icon: "󰖗",
            color: Theme.color4
        },
        "53": {
            icon: "󰖗",
            color: Theme.color4
        },
        "55": {
            icon: "󰖗",
            color: Theme.color4
        },
        "61": {
            icon: "󰖗",
            color: Theme.color6
        },
        "63": {
            icon: "󰖗",
            color: Theme.color6
        },
        "65": {
            icon: "󰖗",
            color: Theme.color6
        },
        "71": {
            icon: "󰖘",
            color: Theme.foreground
        },
        "73": {
            icon: "󰖘",
            color: Theme.foreground
        },
        "75": {
            icon: "󰖘",
            color: Theme.foreground
        },
        "95": {
            icon: "󰖓",
            color: Theme.color13
        }
    }

    function getAppIcon(appClass) {
        if (!appClass)
            return fallback;

        let c = appClass.toLowerCase();
        for (let key in appMap) {
            if (c.includes(key))
                return appMap[key];
        }
        return fallback;
    }
    function getPlayerIcon(player) {
        if (!player)
            return fallback;

        const identity = (player.identity || "").toLowerCase();

        const playerMap = {
            "spotify": "spotify",
            "firefox": "firefox",
            "mozilla firefox": "firefox",
            "chromium": "chromium",
            "google chrome": "google-chrome",
            "brave": "brave-browser",
            "edge": "microsoft-edge",
            "vlc media player": "vlc",
            "vlc": "vlc",
            "mpv": "mpv",
            "plexamp": "plex",
            "spotube": "spotube",
            "youtube music": "google-chrome"
        };

        if (identity in playerMap)
            return getAppIcon(playerMap[identity]);

        return getAppIcon(identity);
    }
    function getWeatherInfo(code, isDay) {
        let c = String(code);

        if (!isDay && (c === "0" || c === "1")) {
            return {
                icon: "󰖔",
                color: Theme.foreground
            };
        }
        if (!isDay && c === "2") {
            return {
                icon: "󰼱",
                color: Theme.color7
            };
        }

        if (c in weatherMap) {
            return weatherMap[c];
        }

        let numericCode = parseInt(code);
        if (numericCode >= 51 && numericCode <= 67)
            return {
                icon: "󰖗",
                color: Theme.color4
            };
        if (numericCode >= 71 && numericCode <= 77)
            return {
                icon: "󰖘",
                color: Theme.foreground
            };
        if (numericCode >= 95)
            return {
                icon: "󰖓",
                color: Theme.color13
            };

        return weatherFallback;
    }
}
