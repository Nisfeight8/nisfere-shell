#!/usr/bin/env bash
#
# dev-mode.sh — toggle ~/.config/nisfere between "installed" (plain
# copies, daemon managed by systemd) and "dev" (symlinked straight to
# this repo checkout, daemon stopped so you run it yourself and see
# live output).
#
# Run install.sh once first — this only toggles daemon/shell/
# templates/themes/templates.json, it doesn't touch packages, the
# systemd unit file itself, or dots/{qtengine,gtk-*,systemd}
# (those rarely change once set up).
#
# Usage:
#   ./dev-mode.sh         auto-detect current state, switch to the other
#   ./dev-mode.sh on      force dev mode
#   ./dev-mode.sh off     force normal (installed) mode

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NISFERE_DIR="$HOME/.config/nisfere"

# What gets toggled — same set install.sh installs from the repo root
# (not the dots/ ones, those stay as-is either way).
ITEMS=(daemon shell templates themes templates.json)

log()  { echo -e "\033[1;34m[nisfere-dev]\033[0m $*"; }
warn() { echo -e "\033[1;33m[nisfere-dev]\033[0m $*"; }
err()  { echo -e "\033[1;31m[nisfere-dev]\033[0m $*" >&2; }

if [[ $EUID -eq 0 ]]; then
    err "Don't run this as root — it operates on your own \$HOME."
    exit 1
fi

if [[ ! -d "$NISFERE_DIR" ]]; then
    err "$NISFERE_DIR doesn't exist yet — run install.sh first."
    exit 1
fi

is_dev_mode() {
    # Dev mode = daemon is a symlink pointing at THIS repo's daemon/.
    [[ -L "$NISFERE_DIR/daemon" ]] || return 1
    [[ "$(readlink -f "$NISFERE_DIR/daemon")" == "$(readlink -f "$REPO_DIR/daemon")" ]]
}

switch_on() {
    log "Switching to DEV mode..."

    log "Killing any running quickshell instance..."
    pkill -x quickshell 2>/dev/null || true

    log "Stopping nisfere-daemon.service (you'll run it manually instead)..."
    systemctl --user stop nisfere-daemon.service 2>/dev/null || true

    for name in "${ITEMS[@]}"; do
        dst="$NISFERE_DIR/$name"
        rm -rf "$dst"
        ln -s "$REPO_DIR/$name" "$dst"
        log "  $name -> symlinked to repo"
    done

    # ~/.config/quickshell already symlinks to $NISFERE_DIR/shell (set
    # up once by install.sh) — now that shell itself points into the
    # repo, it resolves through automatically, nothing else to do.

    echo
    log "Dev mode ON. Edits in $REPO_DIR are live. Run these yourself, in separate terminals, so you can see output/errors:"
    echo "    cd $NISFERE_DIR/daemon && python3 main.py"
    echo "    quickshell"
}

switch_off() {
    log "Switching back to NORMAL (installed) mode..."

    log "Killing any running (dev) quickshell instance..."
    pkill -x quickshell 2>/dev/null || true

    for name in "${ITEMS[@]}"; do
        dst="$NISFERE_DIR/$name"
        rm -rf "$dst"
        cp -r "$REPO_DIR/$name" "$dst"
        log "  $name -> copied from repo"
    done
    # Stray logs shouldn't ship in the fresh copy.
    rm -f "$NISFERE_DIR/daemon/output.log" "$NISFERE_DIR/daemon/output2.log"

    log "Restarting nisfere-daemon.service..."
    systemctl --user daemon-reload
    systemctl --user restart nisfere-daemon.service

    echo
    log "Normal mode ON. Daemon is running via systemd again. Start quickshell yourself now, or it'll come up on your next Hyprland login via exec-once:"
    echo "    quickshell"
}

case "${1:-}" in
    on)
        switch_on
        ;;
    off)
        switch_off
        ;;
    "")
        if is_dev_mode; then
            log "Currently in dev mode -> switching to normal."
            switch_off
        else
            log "Currently in normal mode -> switching to dev."
            switch_on
        fi
        ;;
    *)
        err "Usage: $0 [on|off]"
        exit 1
        ;;
esac
