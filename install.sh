#!/usr/bin/env bash
#
# install.sh — Nisfere shell installer
#
# Installs: Hyprland config, qtengine, GTK settings (all from
# dots/), the daemon + Quickshell shell + templates/themes
# (~/.config/nisfere), all required packages (via yay), fonts,
# systemd --user socket-activated service for the daemon, XDG user
# dirs, and a first-run default theme apply.
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
# to get everything else (packages, systemd units, dotfiles) in place.

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

PACKAGES=(
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
    quickshell
    awww
    adw-gtk-theme
    papirus-icon-theme
    papirus-folders
    breeze
    qtengine
    bibata-cursor-theme
    ttf-noto-nerd
    noto-fonts
    pipewire
    pipewire-pulse
    pipewire-alsa
    pipewire-jack
    wireplumber
    nwg-look
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
    alacritty
    bpytop
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
    pacman-contrib
    python-jinja
    python-psutil
    python-pillow
    python-numpy
)

run yay -S --needed --noconfirm "${PACKAGES[@]}"

log "Packages installed."

log "Enabling NetworkManager.service (system-level, not --user)..."
run sudo systemctl enable --now NetworkManager.service

log "Enabling bluetooth.service (system-level, not --user)..."
run sudo systemctl enable --now bluetooth.service || warn "Could not enable bluetooth.service — probably no Bluetooth hardware on this machine, safe to ignore."

# ── 3. XDG user directories ──────────────────────────────────────────────────

log "Setting up XDG user directories..."
run xdg-user-dirs-update

# ── 4. Dotfiles from dots/ ───────────────────────────────────────────────────

run mkdir -p "$HOME/.config"

log "Installing dotfiles (hypr, qtengine, gtk-3.0, gtk-4.0, xfce4)..."
install_dotdir "hypr"
install_dotdir "fontconfig"
install_dotdir "qtengine"
install_dotdir "gtk-3.0"
install_dotdir "gtk-4.0"
install_dotdir "bpytop"
install_dotdir "alacritty"
install_dotdir "fastfetch"

# ── 4b. Zsh ───────────────────────────────────────────────────────────────────

install_zsh() {
    log "Configuring Zsh..."
    copy_backed_up "$REPO_DIR/dots/zsh/.zshrc" "$HOME/.zshrc"
    copy_backed_up "$REPO_DIR/dots/zsh/.profile" "$HOME/.profile"

    local zsh_dir="$NISFERE_DIR/zsh"
    local plugins_dir="$zsh_dir/plugins"
    run mkdir -p "$plugins_dir"

    local plugin
    for plugin in zsh-syntax-highlighting zsh-autosuggestions zsh-history-substring-search; do
        if [[ ! -d "$plugins_dir/$plugin" ]]; then
            run git clone "https://github.com/zsh-users/$plugin.git" "$plugins_dir/$plugin"
        fi
    done

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
run rm -f "$NISFERE_DIR/daemon/output.log" "$NISFERE_DIR/daemon/output2.log"
copy_backed_up "$REPO_DIR/shell" "$NISFERE_DIR/shell"
copy_backed_up "$REPO_DIR/templates" "$NISFERE_DIR/templates"
copy_backed_up "$REPO_DIR/themes" "$NISFERE_DIR/themes"
copy_backed_up "$REPO_DIR/templates.json" "$NISFERE_DIR/templates.json"

QUICKSHELL_DEFAULT_DIR="$HOME/.config/quickshell"
if [[ -e "$QUICKSHELL_DEFAULT_DIR" || -L "$QUICKSHELL_DEFAULT_DIR" ]]; then
    warn "Existing $QUICKSHELL_DEFAULT_DIR found — backing up to ${QUICKSHELL_DEFAULT_DIR}.bak-$(date +%s)"
    run mv "$QUICKSHELL_DEFAULT_DIR" "${QUICKSHELL_DEFAULT_DIR}.bak-$(date +%s)"
fi
run ln -s "$NISFERE_DIR/shell" "$QUICKSHELL_DEFAULT_DIR"

# ── 6. Cache/data/media directories ──────────────────────────────────────────

log "Creating cache/data directories..."
run mkdir -p "$HOME/.cache/nisfere"
run mkdir -p "$HOME/Pictures/Wallpapers"
run mkdir -p "$HOME/Pictures/Screenshots"
run mkdir -p "$HOME/Videos/Recordings"

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

# ── 7. Icon theme + GSettings ─────────────────────────────────────────────────

log "Applying Papirus icon theme (best-effort gsettings, harmless if it no-ops)..."
run gsettings set org.gnome.desktop.interface icon-theme 'Papirus' || true
run gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' || true

# ── 8. Passwordless pacman for in-UI Arch updates (optional) ─────────────────

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

if [[ $DRY_RUN -eq 1 ]]; then
    warn "Skipping the Docker prompt in dry-run mode."
elif command -v docker >/dev/null 2>&1; then
    log "Docker is already installed — skipping the install prompt."
    if systemctl is-enabled --quiet docker.service 2>/dev/null; then
        log "docker.service is already enabled."
    else
        run sudo systemctl enable --now docker.service
    fi
    if groups "$USER" | grep -qw docker; then
        log "$USER is already in the docker group."
    else
        run sudo usermod -aG docker "$USER"
        log "Added $USER to the docker group — log out and back in for it to take effect."
    fi
else
    echo
    read -r -p "$(echo -e '\033[1;33m[nisfere]\033[0m')  Install Docker Engine (for the Dashboard's Docker tab)? [y/N] " install_docker
    if [[ "$install_docker" =~ ^[Yy]$ ]]; then
        run yay -S --needed --noconfirm docker docker-compose python-docker
        run sudo systemctl enable --now docker.service
        run sudo usermod -aG docker "$USER"
        log "Docker installed and enabled. Log out and back in for group membership to take effect."
    else
        warn "Skipped — the Docker tab won't have anything to show, but nothing else is affected."
    fi
fi
# ── 8c. Display manager (optional) ───────────────────────────────────────────

# Common display managers we might find already active, in case the
# user set one up manually or via a different tool before running this.
KNOWN_DMS=(sddm gdm lightdm ly greetd)

detect_active_dm() {
    local dm
    for dm in "${KNOWN_DMS[@]}"; do
        if systemctl is-enabled --quiet "${dm}.service" 2>/dev/null; then
            echo "$dm"
            return 0
        fi
    done
    return 1
}

if [[ $DRY_RUN -eq 1 ]]; then
    warn "Skipping the SDDM prompt in dry-run mode."
else
    active_dm="$(detect_active_dm || true)"
    if [[ -n "$active_dm" ]]; then
        log "A display manager is already enabled (${active_dm}.service) — skipping the SDDM prompt."
    else
        echo
        read -r -p "$(echo -e '\033[1;33m[nisfere]\033[0m')  Install SDDM (graphical login screen)? [y/N] " install_sddm
        if [[ "$install_sddm" =~ ^[Yy]$ ]]; then
            run yay -S --needed --noconfirm sddm
            run sudo systemctl enable sddm.service
            log "SDDM installed and enabled — will show a login screen starting your NEXT boot."
        else
            warn "Skipped — you'll start Hyprland manually (start-hyprland) from a TTY each boot, or via the prompt at the end of this script for right now."
        fi
    fi
fi

# ── 9. Daemon systemd --user service + socket ────────────────────────────────
# Static files, copied as-is (always — symlinked systemd unit files are
# more trouble than they're worth) — uses systemd's own %h specifier
# (expands to the invoking user's home dir at RUN time) instead of a
# baked-in path, so the unit files themselves never need to know who's
# installing them.
#
# Socket activation: nisfere-daemon.socket is what actually gets
# enabled/started here, NOT nisfere-daemon.service directly. systemd
# owns and creates the socket file itself the moment the .socket unit
# starts — independent of whether the Python daemon has even started
# yet. This is what fixes the race where Quickshell (launched via
# Hyprland's exec-once) could start before the daemon and never
# recover the connection if the timing landed that way. The matching
# .service unit has no [Install] section anymore — systemd starts it
# automatically (same basename convention) the first time something
# actually connects to the socket, so it's never enabled directly.

log "Installing systemd --user service + socket for the daemon..."
run mkdir -p "$HOME/.config/systemd/user"
run cp "$REPO_DIR/dots/systemd/nisfere-daemon.service" "$HOME/.config/systemd/user/nisfere-daemon.service"
run cp "$REPO_DIR/dots/systemd/nisfere-daemon.socket" "$HOME/.config/systemd/user/nisfere-daemon.socket"

run systemctl --user daemon-reload
# Only the .socket gets enabled/started directly. Enabling the
# .service here too would fight with socket activation — it'd try to
# bind/create the socket itself independently instead of receiving the
# already-open fd systemd hands it on first connection.
run systemctl --user enable --now nisfere-daemon.socket
log "Daemon socket enabled and listening (daemon service itself starts on-demand, on first connection)."

# ── 10. First-run defaults ───────────────────────────────────────────────────

SOCKET_PATH="/tmp/nisfere-shell.sock"

log "Waiting for the daemon socket to come up..."
# With socket activation (step 9), systemd creates this file the
# instant nisfere-daemon.socket starts — before the Python process
# behind it has even run a single line — so this should succeed on the
# very first check now. The retry loop stays as a cheap safety net
# (e.g. unusually slow systemd, or this unit somehow not enabled) but
# shouldn't ever need more than one iteration in practice.
if [[ $DRY_RUN -eq 0 ]]; then
    for _ in $(seq 1 20); do
        [[ -S "$SOCKET_PATH" ]] && break
        sleep 0.5
    done
    if [[ ! -S "$SOCKET_PATH" ]]; then
        warn "Daemon socket never appeared at $SOCKET_PATH — skipping default theme apply. Check 'systemctl --user status nisfere-daemon.socket nisfere-daemon.service' and 'journalctl --user -u nisfere-daemon' and apply a theme manually from the shell once it's running."
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
echo "  3. systemctl --user status nisfere-daemon.socket nisfere-daemon.service"
echo "     -> the .socket should show 'active (listening)'; the .service starts"
echo "     automatically on first connection, no need to start it yourself."
echo "  4. journalctl --user -u nisfere-daemon -f   -> daemon logs, if anything looks off."

# ── 11. Launch Hyprland now? ─────────────────────────────────────────────────

if [[ $DRY_RUN -eq 1 ]]; then
    warn "Skipping the 'launch Hyprland now' step in dry-run mode."
elif [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    # Already running inside an active Hyprland session (e.g. re-running
    # install.sh to pick up new dotfiles/packages) — nothing to launch.
    # Just reload the config and make sure Quickshell is running.
    log "Detected an active Hyprland session — reloading config instead of launching a new one."
    run hyprctl reload

    if ! pgrep -x quickshell >/dev/null 2>&1; then
        log "Quickshell isn't running — starting it in the background."
        run bash -c "mkdir -p '$HOME/.cache/nisfere' && quickshell > '$HOME/.cache/nisfere/quickshell.log' 2>&1 &"
    else
        log "Quickshell is already running — leaving it as is."
    fi
elif [[ -n "${SSH_CONNECTION:-}${SSH_TTY:-}" ]]; then
    warn "Detected an SSH session — can't launch a Wayland/Hyprland session from here (no real seat/display to render into). Log in on the actual console/TTY and run 'Hyprland', or reboot into it."
else
    echo
    read -r -p "$(echo -e '\033[1;33m[nisfere]\033[0m')  Launch Hyprland now? (replaces this shell session) [y/N] " launch_now
    if [[ "$launch_now" =~ ^[Yy]$ ]]; then
        log "Launching Hyprland via start-hyprland..."
        exec start-hyprland
    else
        log "Skipped — log out and start a Hyprland session (or reboot) whenever you're ready."
    fi
fi