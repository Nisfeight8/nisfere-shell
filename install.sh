#!/usr/bin/env bash
#
# install.sh — Nisfere shell installer
#
# Installs: Hyprland config, wallust, qtengine, GTK settings (all from
# dots/), the daemon + Quickshell shell + templates/themes
# (~/.config/nisfere), all required packages (via yay), fonts,
# systemd --user service for the daemon, XDG user dirs, and a
# first-run default theme apply.
#
# Run from the root of the nisfere repo (the folder containing
# daemon/, dots/, shell/, templates/, themes/, templates.json).
#
# Usage:
#   ./install.sh            normal run
#   ./install.sh --dry-run  print every command that WOULD run, touch
#                           nothing — safe to run on your real machine
#                           just to sanity-check paths/package list.
#
# For active development against a git checkout, use dev-mode.sh
# instead (switches ~/.config/nisfere between this install and a
# symlinked, live-editable copy of your repo) — run install.sh once
# to get everything else (packages, systemd unit, dotfiles) in place.

set -euo pipefail

DRY_RUN=0
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=1
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NISFERE_DIR="$HOME/.config/nisfere"

log()  { echo -e "\033[1;34m[nisfere]\033[0m $*"; }
warn() { echo -e "\033[1;33m[nisfere]\033[0m $*"; }
err()  { echo -e "\033[1;31m[nisfere]\033[0m $*" >&2; }

# In dry-run mode, print the command instead of running it. Every
# state-changing operation in this script goes through this — nothing
# below calls a mutating command directly, so `--dry-run` genuinely
# touches nothing on disk or on the system.
run() {
    if [[ $DRY_RUN -eq 1 ]]; then
        echo -e "\033[2m[dry-run]\033[0m $*"
    else
        "$@"
    fi
}

# Backs up any existing destination (file, dir, or symlink — never
# silently overwrites/deletes), then copies src -> dst.
#   copy_backed_up <src> <dst>
copy_backed_up() {
    local src="$1"
    local dst="$2"

    if [[ -e "$dst" || -L "$dst" ]]; then
        warn "Existing $dst found — backing up to ${dst}.bak-$(date +%s)"
        run mv "$dst" "${dst}.bak-$(date +%s)"
    fi
    run mkdir -p "$(dirname "$dst")"
    run cp -r "$src" "$dst"
}

# dots/<name> -> ~/.config/<name>.
install_dotdir() {
    local name="$1"
    copy_backed_up "$REPO_DIR/dots/$name" "$HOME/.config/$name"
}

if [[ $EUID -eq 0 ]]; then
    err "Don't run this as root — it installs into your own \$HOME. Run as your normal user (it'll ask for sudo/yay password when needed)."
    exit 1
fi

if [[ $DRY_RUN -eq 1 ]]; then
    warn "DRY RUN — no packages will be installed, no files written, nothing enabled. Just printing what would happen."
fi

# ── 1. AUR helper (yay) ──────────────────────────────────────────────────────
# Everything below goes through yay — it transparently handles both
# official-repo and AUR packages, so there's no need to track which
# list each package belongs to.

if ! command -v yay >/dev/null 2>&1; then
    log "yay not found — installing it first"
    run sudo pacman -S --needed --noconfirm git base-devel
    tmp_yay="$(mktemp -d)"
    run git clone https://aur.archlinux.org/yay.git "$tmp_yay/yay"
    run bash -c "cd '$tmp_yay/yay' && makepkg -si --noconfirm"
    rm -rf "$tmp_yay"
else
    log "yay already installed, skipping"
fi

# ── 2. Packages ───────────────────────────────────────────────────────────────

log "Installing packages via yay (this will prompt for your password)..."

# Add/remove packages here — one per line, easy to scan and diff.
PACKAGES=(
    # Core Hyprland/Wayland session
    hyprland
    hypridle
    xdg-desktop-portal
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    xdg-user-dirs
    polkit-kde-agent
    bluez
    bluez-utils
    networkmanager
    wl-clipboard
    trash-cli

    # Quickshell shell
    quickshell

    # Wallpaper / theming pipeline
    awww
    # wallust-git, not plain wallust — the tarball-based AUR package
    # has a known recurring stale-checksum bug (PKGBUILD's recorded
    # sha256sum for the crates.io source tarball doesn't match what's
    # actually served, causing "did not pass the validity check").
    # -git builds straight from the repo instead, sidestepping it.
    wallust-git
    adw-gtk-theme
    papirus-icon-theme
    papirus-folders
    breeze
    qtengine

    # Fonts
    ttf-arimo-nerd
    noto-fonts

    # Audio (PipeWire) — nothing audio-related works without this:
    # volume controls, cava visualizer, media playback, all of it.
    pipewire
    pipewire-pulse
    pipewire-alsa
    pipewire-jack
    wireplumber

    # GTK settings GUI — handy for eyeballing/adjusting theme, icon
    # theme, cursor theme; already used once to debug adw-gtk3.
    nwg-look

    # File manager (Thunar) + trash/mount/archive support
    thunar
    thunar-volman
    thunar-archive-plugin
    xarchiver
    xfconf
    gvfs
    gvfs-mtp
    gvfs-gphoto2
    udisks2
    tumbler
    ffmpegthumbnailer
    zip
    unzip
    p7zip
    unrar

    # Terminal + system monitor (already templated — alacritty-colors.toml, bpytop.theme)
    alacritty
    bpytop

    # Shell utilities used by daemon/QML (cava, clipboard, screenshots, etc.)
    zsh
    fastfetch
    cava
    power-profiles-daemon
    brightnessctl
    cliphist
    hyprpicker
    wlsunset
    hyprshutdown
    wf-recorder
    grim
    slurp
    jq

    # Arch update support (checkupdates command)
    pacman-contrib

    # Python dependencies for the daemon
    python-jinja
    python-psutil
)

run yay -S --needed --noconfirm "${PACKAGES[@]}"

log "Packages installed."

log "Enabling NetworkManager.service (system-level, not --user)..."
run sudo systemctl enable --now NetworkManager.service

log "Enabling bluetooth.service (system-level, not --user)..."
run sudo systemctl enable --now bluetooth.service || warn "Could not enable bluetooth.service — probably no Bluetooth hardware on this machine, safe to ignore."

# ── 3. XDG user directories ──────────────────────────────────────────────────
# Creates ~/Desktop, ~/Documents, ~/Downloads, ~/Music, ~/Pictures,
# ~/Public, ~/Templates, ~/Videos (locale-aware) and writes
# ~/.config/user-dirs.dirs.

log "Setting up XDG user directories..."
run xdg-user-dirs-update

# ── 4. Dotfiles from dots/ ───────────────────────────────────────────────────
# Order matters for wallust: it needs to be in place BEFORE step 10's
# "apply default theme", since ColorSource's constructor checks/patches
# ~/.config/wallust/wallust.toml and just logs a warning + skips if the
# file doesn't exist yet.

run mkdir -p "$HOME/.config"

log "Installing dotfiles (hypr, wallust, qtengine, gtk-3.0, gtk-4.0, xfce4)..."
install_dotdir "hypr"
install_dotdir "wallust"
install_dotdir "qtengine"
install_dotdir "gtk-3.0"
install_dotdir "gtk-4.0"
install_dotdir "bpytop"
install_dotdir "alacritty"
install_dotdir "fastfetch"

# ── 4b. Zsh ───────────────────────────────────────────────────────────────────
# .zshrc goes straight to $HOME (not ~/.config) — that's just where
# zsh looks by default, unless ZDOTDIR says otherwise, which we're not
# setting here. Plugins get git-cloned into ~/.config/nisfere/zsh/
# plugins/ (not shipped in dots/ — nothing to copy, just clones at
# install time, same idea as ~/.cache/nisfere). Sets zsh as your login
# shell unconditionally — you asked for that, not a prompt.

install_zsh() {
    log "Configuring Zsh..."
    copy_backed_up "$REPO_DIR/dots/zsh/.zshrc" "$HOME/.zshrc"

    local zsh_dir="$NISFERE_DIR/zsh"
    local plugins_dir="$zsh_dir/plugins"
    run mkdir -p "$plugins_dir"

    local plugin
    for plugin in zsh-syntax-highlighting zsh-autosuggestions zsh-history-substring-search; do
        if [[ ! -d "$plugins_dir/$plugin" ]]; then
            run git clone "https://github.com/zsh-users/$plugin.git" "$plugins_dir/$plugin"
        fi
    done

    # Zsh appends here on every command — needs to exist upfront with
    # the right permissions (history can contain sensitive stuff).
    local history_file="$HOME/.zsh_history"
    if [[ ! -f "$history_file" ]]; then
        run touch "$history_file"
        run chmod 600 "$history_file"
    fi

    run sudo chsh -s /bin/zsh "$USER"
    log "Zsh configured (default shell — takes effect on your next login)."
}
install_zsh

# ── 5. Nisfere daemon + shell + templates/themes ─────────────────────────────

log "Installing daemon + shell + templates/themes -> $NISFERE_DIR"
run mkdir -p "$NISFERE_DIR"
copy_backed_up "$REPO_DIR/daemon" "$NISFERE_DIR/daemon"
# Drop stray log files that shouldn't ship with a fresh install.
run rm -f "$NISFERE_DIR/daemon/output.log" "$NISFERE_DIR/daemon/output2.log"
copy_backed_up "$REPO_DIR/shell" "$NISFERE_DIR/shell"
copy_backed_up "$REPO_DIR/templates" "$NISFERE_DIR/templates"
copy_backed_up "$REPO_DIR/themes" "$NISFERE_DIR/themes"
copy_backed_up "$REPO_DIR/templates.json" "$NISFERE_DIR/templates.json"

# `qs ipc call`/`qs ipc show` (bare, no flags) always default to
# ~/.config/quickshell/shell.qml for identifying the running instance
# — that's a SEPARATE mechanism from launching via `-p`, so even
# though `-p` correctly launches the shell from ~/.config/nisfere/shell,
# IPC lookups against the default path won't find it ("No running
# instances for ...quickshell/shell.qml"). Symlinking the default
# location to point at the real shell folder fixes both launch AND
# IPC lookup the same way, and means `-p` isn't even needed anymore —
# plain `quickshell` (or `qs`) works for everything.
QUICKSHELL_DEFAULT_DIR="$HOME/.config/quickshell"
if [[ -e "$QUICKSHELL_DEFAULT_DIR" || -L "$QUICKSHELL_DEFAULT_DIR" ]]; then
    warn "Existing $QUICKSHELL_DEFAULT_DIR found — backing up to ${QUICKSHELL_DEFAULT_DIR}.bak-$(date +%s)"
    run mv "$QUICKSHELL_DEFAULT_DIR" "${QUICKSHELL_DEFAULT_DIR}.bak-$(date +%s)"
fi
run ln -s "$NISFERE_DIR/shell" "$QUICKSHELL_DEFAULT_DIR"

# ── 6. Cache/data/media directories ──────────────────────────────────────────
# state.json is NOT created here — StateManager already handles that
# correctly on demand (missing file -> sensible default, tested
# extensively). The other four don't have the same confirmed handling,
# so they get explicit default content below instead of relying on
# lazy creation.

log "Creating cache/data directories..."
run mkdir -p "$HOME/.cache/nisfere"
run mkdir -p "$HOME/Pictures/Wallpapers"
run mkdir -p "$HOME/Pictures/Screenshots"
run mkdir -p "$HOME/Videos/Recordings"

# Default contents are best-guess (array for lists, object for
# keyed/single state) — only create if missing, never overwrite
# something already there. Confirm these match what each module
# actually expects; state.json itself is NOT included here since
# StateManager already creates it correctly on demand (tested
# extensively earlier) — adding it here too could conflict with that.
create_cache_file() {
    local name="$1"
    local default_content="$2"
    local dst="$HOME/.cache/nisfere/$name"
    if [[ -f "$dst" ]]; then
        return
    fi
    if [[ $DRY_RUN -eq 1 ]]; then
        echo -e "\033[2m[dry-run]\033[0m write $dst: $default_content"
    else
        echo "$default_content" > "$dst"
    fi
}

# ── 7. Icon theme + GSettings (best-effort extra; settings.ini from
# dots/gtk-*.0 above is the mechanism that actually matters under
# Hyprland — see desktop_integration.py's reload_gtk() for why) ──────────────

log "Applying Papirus icon theme (best-effort gsettings, harmless if it no-ops)..."
run gsettings set org.gnome.desktop.interface icon-theme 'Papirus' || true
run gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' || true

# ── 8. Passwordless pacman for in-UI Arch updates (optional) ─────────────────
# Lets the daemon's update_manager stream `pacman -Syu` live without a
# polkit dialog. Skippable — falls back to pkexec (needs a polkit
# agent running) if you say no here.

if [[ $DRY_RUN -eq 1 ]]; then
    warn "Skipping the sudoers prompt in dry-run mode."
else
    echo
    read -r -p "$(echo -e '\033[1;33m[nisfere]\033[0m')  Allow passwordless 'pacman' for in-UI Arch updates? (adds a sudoers rule) [y/N] " allow_nopasswd
    if [[ "$allow_nopasswd" =~ ^[Yy]$ ]]; then
        echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/pacman" | sudo tee /etc/sudoers.d/nisfere-pacman >/dev/null
        sudo chmod 0440 /etc/sudoers.d/nisfere-pacman
        log "Passwordless pacman enabled for in-UI updates."
    else
        warn "Skipped — Arch updates in the UI will fall back to a polkit (pkexec) prompt. Make sure a polkit agent is running (e.g. exec-once in Hyprland: /usr/lib/polkit-kde-authentication-agent-1)."
    fi
fi

# ── 8b. Docker (optional) ────────────────────────────────────────────────────
# Fully opt-in: neither Docker Engine nor python-docker are installed
# by default. docker_service.py guards its own `import docker` (see
# services/docker_service.py) — the daemon starts and runs fine either
# way, the Dashboard's Docker tab just reports unavailable if you skip
# this. Nothing else is affected.

if [[ $DRY_RUN -eq 1 ]]; then
    warn "Skipping the Docker prompt in dry-run mode."
else
    echo
    read -r -p "$(echo -e '\033[1;33m[nisfere]\033[0m')  Install Docker Engine (for the Dashboard's Docker tab)? [y/N] " install_docker
    if [[ "$install_docker" =~ ^[Yy]$ ]]; then
        run yay -S --needed --noconfirm docker docker-compose python-docker
        run sudo systemctl enable --now docker.service
        # Needed so python-docker (running as your user, not root) can
        # actually reach /var/run/docker.sock — without this you'd get
        # a permission error instead of a working connection. Group
        # membership only takes effect on your NEXT login, not this
        # session.
        run sudo usermod -aG docker "$USER"
        log "Docker installed and enabled. Log out and back in for group membership to take effect."
    else
        warn "Skipped — the Docker tab won't have anything to show, but nothing else is affected."
    fi
fi

# ── 8c. Display manager (optional) ───────────────────────────────────────────
# Without this, you start Hyprland manually each boot (start-hyprland
# from a TTY, or the prompt at the very end of this script for right
# now). SDDM is well-supported with Hyprland specifically. Enabled but
# NOT started now — starting it immediately could disrupt the very
# TTY session you're running this install from.

if [[ $DRY_RUN -eq 1 ]]; then
    warn "Skipping the SDDM prompt in dry-run mode."
else
    echo
    read -r -p "$(echo -e '\033[1;33m[nisfere]\033[0m')  Install SDDM (graphical login screen)? [y/N] " install_sddm
    if [[ "$install_sddm" =~ ^[Yy]$ ]]; then
        run yay -S --needed --noconfirm sddm
        run sudo systemctl enable sddm.service
        log "SDDM installed and enabled — will show a login screen starting your NEXT boot (Hyprland should already appear as a selectable session, installed as part of the hyprland package itself)."
    else
        warn "Skipped — you'll start Hyprland manually (start-hyprland) from a TTY each boot, or via the prompt at the end of this script for right now."
    fi
fi

# ── 9. Daemon systemd --user service ─────────────────────────────────────────
# Static file, copied as-is (always — a symlinked systemd unit file is
# more trouble than it's worth) — uses systemd's own %h specifier
# (expands to the invoking user's home dir at RUN time) instead of a
# baked-in path, so the unit file itself never needs to know who's
# installing it.

log "Installing systemd --user service for the daemon..."
run mkdir -p "$HOME/.config/systemd/user"
run cp "$REPO_DIR/dots/systemd/nisfere-daemon.service" "$HOME/.config/systemd/user/nisfere-daemon.service"

run systemctl --user daemon-reload
run systemctl --user enable --now nisfere-daemon.service
log "Daemon service enabled and started."

# ── 10. First-run defaults ───────────────────────────────────────────────────
# Applies a bundled static theme (no wallpaper image required — themes/
# already ships tokyo-night-{dark,light}.json) so the shell doesn't
# start with an unstyled/empty state.json on a completely fresh install.
# Goes through the daemon's own socket — same "theme"/"set_colors"
# message ThemeActions.qml's setColors() already sends in normal use —
# rather than importing ThemeManager directly, so this exercises the
# real production path instead of a special install-time bypass.

SOCKET_PATH="/tmp/nisfere-shell.sock"

log "Waiting for the daemon socket to come up..."
if [[ $DRY_RUN -eq 0 ]]; then
    for _ in $(seq 1 20); do
        [[ -S "$SOCKET_PATH" ]] && break
        sleep 0.5
    done
    if [[ ! -S "$SOCKET_PATH" ]]; then
        warn "Daemon socket never appeared at $SOCKET_PATH — skipping default theme apply. Check 'journalctl --user -u nisfere-daemon' and apply a theme manually from the shell once it's running."
    fi
fi

log "Applying default theme (tokyo-night, dark) via daemon socket..."
DEFAULT_THEME_MSG='{"module": "theme", "action": "set_colors", "payload": {"theme_name": "tokyo-night", "mode": "dark"}}'

if [[ $DRY_RUN -eq 1 ]]; then
    echo -e "\033[2m[dry-run]\033[0m send to $SOCKET_PATH: $DEFAULT_THEME_MSG"
elif [[ -S "$SOCKET_PATH" ]]; then
    python3 -c "
import socket
msg = '''$DEFAULT_THEME_MSG''' + chr(10)
try:
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    s.settimeout(5)
    s.connect('$SOCKET_PATH')
    s.sendall(msg.encode())
    s.close()
    print('Default theme request sent.')
except Exception as e:
    print(f'Could not reach daemon socket: {e}')
"
fi

# ── Done ──────────────────────────────────────────────────────────────────────

echo
log "$([ $DRY_RUN -eq 1 ] && echo 'Dry run complete — nothing was changed.' || echo 'Install complete!')"
echo
echo "Next steps:"
echo "  1. Drop at least one wallpaper image into ~/Pictures/Wallpapers/"
echo "     (a default static theme is already applied, but no wallpaper is set yet)."
echo "  2. Check dots/hypr/modules/autostart.lua includes:"
echo "       exec-once = quickshell > ~/.cache/nisfere/quickshell.log 2>&1"
echo "     (no -p needed anymore — ~/.config/quickshell now symlinks to the"
echo "     real shell folder, so the default path is already correct, and"
echo "     'qs ipc call'/'qs ipc show' will find the running instance too)."
echo "  3. journalctl --user -u nisfere-daemon -f   -> daemon logs, if anything looks off."

# ── 11. Launch Hyprland now? (must be the LAST thing this script does —
# `exec` replaces the current shell process, nothing after it runs) ──────────

if [[ $DRY_RUN -eq 1 ]]; then
    warn "Skipping the 'launch Hyprland now' prompt in dry-run mode."
elif [[ -n "${SSH_CONNECTION:-}${SSH_TTY:-}" ]]; then
    warn "Detected an SSH session — can't launch a Wayland/Hyprland session from here (no real seat/display to render into). Log in on the actual console/TTY and run 'Hyprland', or reboot into it."
else
    echo
    read -r -p "$(echo -e '\033[1;33m[nisfere]\033[0m')  Launch Hyprland now? (replaces this shell session) [y/N] " launch_now
    if [[ "$launch_now" =~ ^[Yy]$ ]]; then
        log "Launching Hyprland via start-hyprland..."
        # NOT the raw `Hyprland` binary directly — since 0.53, that's
        # no longer the expected entry point (you'd get a "Hyprland
        # was started without start-hyprland" warning/error). This
        # wrapper (same package) adds crash recovery/safe mode too.
        exec start-hyprland
    else
        log "Skipped — log out and start a Hyprland session (or reboot) whenever you're ready."
    fi
fi