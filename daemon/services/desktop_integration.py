"""
DesktopIntegration — everything that reaches out and pokes the running
desktop: setting the wallpaper via awww, recoloring Papirus folders,
forcing GTK to reload. No state, no rendering, no color extraction —
just OS-facing side effects. Threading policy for these lives with the
caller (ThemeManager), not here, so it stays in one place.
"""

import logging
import subprocess
from pathlib import Path

from .color_utils import hue_to_papirus_color

logger = logging.getLogger(__name__)


class DesktopIntegration:
    def apply_wallpaper(self, path: str) -> None:
        subprocess.run(
            ["awww", "img", path, "--transition-type", "center"], check=False
        )

    def preview_wallpaper(self, path: str) -> None:
        subprocess.run(
            ["awww", "img", path, "--transition-type", "none"], check=False
        )

    def sync_papirus_folders(self, accent_hex: str) -> None:
        """
        Recolors Papirus folder icons to match the current accent color.
        Requires: papirus-folders installed + papirus icon theme.
        Uses sudo -n (non-interactive) — add to sudoers if needed:
          username ALL=(ALL) NOPASSWD: /usr/bin/papirus-folders

        Shells out twice and can take a moment — callers should run
        this in a background thread rather than blocking on it.
        """
        try:
            if (
                subprocess.run(
                    ["which", "papirus-folders"], capture_output=True, check=False
                ).returncode
                != 0
            ):
                return

            papirus_paths = [
                Path("/usr/share/icons/Papirus"),
                Path("/usr/share/icons/Papirus-Dark"),
                Path.home() / ".local/share/icons/Papirus",
                Path.home() / ".icons/Papirus",
            ]
            if not any(p.exists() for p in papirus_paths):
                return

            hex_color = accent_hex.lstrip("#")
            if len(hex_color) != 6:
                return

            r, g, b = (int(hex_color[i : i + 2], 16) for i in (0, 2, 4))
            max_val = max(r, g, b)
            min_val = min(r, g, b)
            delta = max_val - min_val

            saturation = 0 if max_val == 0 else (delta * 100) // max_val
            brightness = max_val

            if saturation < 20:
                color = (
                    "black"
                    if brightness < 85
                    else "grey" if brightness < 170 else "white"
                )
            else:
                if max_val == r:
                    hue = 60 * (((g - b) / delta) % 6)
                elif max_val == g:
                    hue = 60 * ((b - r) / delta + 2)
                else:
                    hue = 60 * ((r - g) / delta + 4)

                pale = saturation < 60 and brightness > 180
                color = hue_to_papirus_color(hue, pale)

            # Detect which Papirus variant is currently active
            icon_theme_result = subprocess.run(
                ["gsettings", "get", "org.gnome.desktop.interface", "icon-theme"],
                capture_output=True,
                text=True,
                check=False,
            )
            active_icon_theme = icon_theme_result.stdout.strip().strip("'")
            papirus_theme = (
                active_icon_theme if "apirus" in active_icon_theme else "Papirus-Dark"
            )

            # Run and wait so icon cache is updated before GTK reload
            subprocess.run(
                ["papirus-folders", "-C", color, "--theme", papirus_theme],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                check=False,
            )
            logger.info(
                "Papirus folders → %s (theme=%s accent=%s)",
                color,
                papirus_theme,
                accent_hex,
            )

        except Exception as e:
            logger.warning("Papirus sync failed: %s", e)

    def reload_gtk(self, mode: str) -> None:
        """
        Forces GTK3/4 apps to reload colors live.
        - Uses adw-gtk3 (no dark/light suffix) — our CSS variables handle colors.
        - Toggles gtk-theme name to trigger a CSS reload in all GTK apps.
        """
        try:
            gtk_theme = "adw-gtk3-dark" if mode == "dark" else "adw-gtk3"
            subprocess.run(
                ["gsettings", "set", "org.gnome.desktop.interface", "gtk-theme", gtk_theme],
                check=False,
            )
            logger.debug("GTK reloaded (mode=%s)", mode)
        except Exception as e:
            logger.warning("GTK reload failed: %s", e)
