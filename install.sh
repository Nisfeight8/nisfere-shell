#!/usr/bin/env bash
# =============================================================================
# Nisfere — Install Script (Arch Linux)
# =============================================================================
set -uo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${BLUE}::${RESET} $*"; }
success() { echo -e "${GREEN}✓${RESET}  $*"; }
warn()    { echo -e "${YELLOW}!${RESET}  $*"; }
error()   { echo -e "${RED}✗${RESET}  $*"; exit 1; }
section() { echo -e "\n${BOLD}── $* ──${RESET}"; }

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
info "Repo root: $REPO_DIR"

# ── AUR helper ────────────────────────────────────────────────────────────────
detect_aur() {
    for h in yay paru; do
        command -v "$h" &>/dev/null && echo "$h" && return
    done
    error "No AUR helper found (yay/paru). Install one first."
}

# =============================================================================
# 1. Dependencies
# =============================================================================
section "Installing dependencies"

PACMAN_DEPS=(
    # Python daemon
    python
    python-jinja
    python-docker
    python-psutil
    
    # Qt6 + QuickShell runtime
    qt6-base
    qt6-declarative
    qt6-wayland
    qt6-5compat
    qt6-svg
    
    # Theming
    adw-gtk3
    papirus-icon-theme
    breeze            # Qt widget style for qtengine
    
    # Wallpaper
    swww
    
    # Audio
    cava
    pipewire
    wireplumber
    playerctl
    
    # System
    brightnessctl
    networkmanager
    hypridle
    
    # Portals
    xdg-desktop-portal
    xdg-desktop-portal-gtk
    xdg-desktop-portal-hyprland
    
    # Tools
    dconf
    gtk-update-icon-cache
)

AUR_DEPS=(
    quickshell-git    # The shell
    wallust           # Dynamic color generation
    papirus-folders   # Recolor Papirus folder icons
    qtengine          # Qt platform theme with KColorScheme
)

info "Installing pacman packages..."
sudo pacman -S --needed --noconfirm "${PACMAN_DEPS[@]}" \
|| warn "Some pacman packages may have failed — check manually"

AUR=$(detect_aur)
info "Installing AUR packages with $AUR..."
$AUR -S --needed --noconfirm "${AUR_DEPS[@]}" \
|| warn "Some AUR packages may have failed — check manually"

success "Dependencies done"

# =============================================================================
# 2. Directory structure
# =============================================================================
section "Creating directories"

dirs=(
    "$HOME/.config/nisfere/templates"
    "$HOME/.config/nisfere/themes"
    "$HOME/.cache/nisfere"
    "$HOME/.config/wallust"
    "$HOME/.config/qtengine"
    "$HOME/.config/cava"
    "$HOME/.config/hypr"
    "$HOME/.config/systemd/user/xdg-desktop-portal.service.d"
    "$HOME/.local/share/icons"
    "$HOME/Pictures/Wallpapers"
)

for d in "${dirs[@]}"; do
    mkdir -p "$d" && success "$d"
done

# =============================================================================
# 3. Copy repo files
# =============================================================================
section "Copying config files"

# ── Templates ─────────────────────────────────────────────────────────────────
if [[ -d "$REPO_DIR/templates" ]]; then
    cp -v "$REPO_DIR/templates/"* "$HOME/.config/nisfere/templates/"
    success "Templates → ~/.config/nisfere/templates/"
else
    warn "templates/ not found in repo"
fi

# ── templates.json ────────────────────────────────────────────────────────────
if [[ -f "$REPO_DIR/templates.json" ]]; then
    cp -v "$REPO_DIR/templates.json" "$HOME/.config/nisfere/templates.json"
    success "templates.json → ~/.config/nisfere/templates.json"
else
    cat > "$HOME/.config/nisfere/templates.json" << 'JSON'
{
  "alacritty-colors.toml": "~/.config/alacritty/colors.toml",
  "hyprland-colors.conf":  "~/.config/hypr/conf/colors.conf",
  "adw-gtk3.css": [
    "~/.config/gtk-3.0/gtk.css",
    "~/.config/gtk-4.0/gtk.css"
  ],
  "thunar.css": [
    "~/.config/gtk-3.0/thunar.css",
    "~/.config/gtk-4.0/thunar.css"
  ],
  "nisfere.colors": "~/.config/qtengine/nisfere.colors"
}
JSON
    success "Created default templates.json"
fi

# ── Themes ────────────────────────────────────────────────────────────────────
if [[ -d "$REPO_DIR/themes" ]]; then
    cp -v "$REPO_DIR/themes/"*.json "$HOME/.config/nisfere/themes/"
    success "Themes → ~/.config/nisfere/themes/"
fi

# ── Hyprland configs ──────────────────────────────────────────────────────────
if [[ -d "$REPO_DIR/hypr" ]]; then
    cp -rv "$REPO_DIR/hypr/"* "$HOME/.config/hypr/"
    success "hypr/ → ~/.config/hypr/"
fi

# ── Cava config ───────────────────────────────────────────────────────────────
CAVA_SRC="$REPO_DIR/shell/assets/cava.conf"
if [[ -f "$CAVA_SRC" ]]; then
    cp -v "$CAVA_SRC" "$HOME/.config/cava/config"
    success "cava.conf → ~/.config/cava/config"
fi

# =============================================================================
# 4. Cache files
# =============================================================================
section "Setting up cache files"

# notifications.json — empty array on first install
NOTIF="$HOME/.cache/nisfere/notifications.json"
[[ ! -f "$NOTIF" ]] && echo "[]" > "$NOTIF" && success "Created notifications.json"

# nightlight_state — off by default
NIGHTLIGHT="$HOME/.cache/nisfere/nightlight_state"
[[ ! -f "$NIGHTLIGHT" ]] && echo "off" > "$NIGHTLIGHT" && success "Created nightlight_state"

# =============================================================================
# 5. Wallust config
# =============================================================================
section "Configuring wallust"

WALLUST_CFG="$HOME/.config/wallust/wallust.toml"
if [[ ! -f "$WALLUST_CFG" ]]; then
    cat > "$WALLUST_CFG" << 'TOML'
backend        = "thumb"
color_space    = "lab"
threshold      = 5
palette        = "dark16"
generation     = "interpolate"
check_contrast = true
alpha          = 100

[templates]
wallust = { src = 'colors.json', dst = '~/.cache/wallust/colors.json' }
TOML
    success "Created wallust.toml"
else
    if ! grep -q "colors.json" "$WALLUST_CFG"; then
        printf '\n[templates]\nwallust = { src = '"'"'colors.json'"'"', dst = '"'"'~/.cache/wallust/colors.json'"'"' }\n' \
        >> "$WALLUST_CFG"
        success "Patched wallust.toml"
    else
        success "wallust.toml already configured"
    fi
fi

# =============================================================================
# 6. Papirus local install (papirus-folders without sudo)
# =============================================================================
section "Installing Papirus icons locally"

for variant in Papirus Papirus-Dark; do
    src="/usr/share/icons/$variant"
    dst="$HOME/.local/share/icons/$variant"
    if [[ -d "$src" && ! -d "$dst" ]]; then
        info "Copying $variant (~300MB, please wait)..."
        cp -r "$src" "$dst"
        gtk-update-icon-cache -f -t "$dst" 2>/dev/null || true
        success "Copied $variant"
        elif [[ -d "$dst" ]]; then
        success "$variant already local"
    else
        warn "$variant not in /usr/share/icons/ — install papirus-icon-theme"
    fi
done

# =============================================================================
# 7. XDG Desktop Portal fix
# =============================================================================
section "Fixing XDG Desktop Portal (SDDM + Hyprland)"

cat > "$HOME/.config/systemd/user/xdg-desktop-portal.service.d/override.conf" << 'SYSTEMD'
[Unit]
Description=Portal service
Requires=dbus.service
After=dbus.service

[Service]
Type=dbus
BusName=org.freedesktop.portal.Desktop
ExecStart=/usr/lib/xdg-desktop-portal
Slice=session.slice
SYSTEMD
systemctl --user daemon-reload 2>/dev/null || true
success "XDG portal override installed"

# =============================================================================
# 8. GTK / gsettings
# =============================================================================
section "Configuring GTK"

gsettings set org.gnome.desktop.interface gtk-theme    'adw-gtk3'    2>/dev/null || true
gsettings set org.gnome.desktop.interface icon-theme   'Papirus-Dark' 2>/dev/null || true
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'  2>/dev/null || true
success "GTK settings applied"

# =============================================================================
# 9. Systemd user service
# =============================================================================
section "Installing daemon service"

cat > "$HOME/.config/systemd/user/nisfere-daemon.service" << SYSTEMD
[Unit]
Description=Nisfere Shell Daemon
After=graphical-session.target
PartOf=graphical-session.target

[Service]
Type=simple
WorkingDirectory=${REPO_DIR}/daemon
ExecStart=/usr/bin/python ${REPO_DIR}/daemon/main.py
Restart=on-failure
RestartSec=3
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=graphical-session.target
SYSTEMD

systemctl --user daemon-reload
systemctl --user enable nisfere-daemon.service
success "Daemon service installed and enabled"

# =============================================================================
# 10. Final instructions
# =============================================================================
section "Done! Manual steps"

cat << INSTRUCTIONS

${BOLD}Add to ~/.config/hypr/hyprland.conf:${RESET}

  ${YELLOW}# Environment${RESET}
  env = QT_QPA_PLATFORMTHEME, qtengine
  env = GTK_THEME, adw-gtk3

  ${YELLOW}# Portal (must be before portal exec-once)${RESET}
  exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE XDG_SESSION_TYPE
  exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE XDG_SESSION_TYPE
  exec-once = systemctl --user start xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xdg-desktop-portal

  ${YELLOW}# Nisfere${RESET}
  exec-once = systemctl --user start nisfere-daemon
  exec-once = quickshell -p ${REPO_DIR}/shell

  ${YELLOW}# Cursor (managed by daemon after first theme apply)${RESET}
  source = ~/.config/hypr/conf/cursor.conf

${BOLD}Then re-login and apply a theme from the picker!${RESET}
INSTRUCTIONS

success "Installation complete 🎉"