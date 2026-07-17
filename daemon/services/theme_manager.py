import json
import logging
import os
import subprocess
from dataclasses import dataclass, field
from pathlib import Path
import threading

from jinja2 import Environment, StrictUndefined

logger = logging.getLogger(__name__)


# ── Jinja2 Filters ──────────────────────────────────────────────────────────


def filter_strip(hex_val: str) -> str:
    return hex_val.lstrip("#") if isinstance(hex_val, str) else hex_val


def filter_lighten(hex_val: str, amount: float = 0.1) -> str:
    hex_val = hex_val.lstrip("#")
    rgb = [int(hex_val[i : i + 2], 16) for i in (0, 2, 4)]
    new_rgb = [min(255, int(c + (255 - c) * amount)) for c in rgb]
    return f"#{new_rgb[0]:02x}{new_rgb[1]:02x}{new_rgb[2]:02x}"


def filter_darken(hex_val: str, amount: float = 0.1) -> str:
    hex_val = hex_val.lstrip("#")
    rgb = [int(hex_val[i : i + 2], 16) for i in (0, 2, 4)]
    new_rgb = [max(0, int(c * (1 - amount))) for c in rgb]
    return f"#{new_rgb[0]:02x}{new_rgb[1]:02x}{new_rgb[2]:02x}"


def filter_rgb(hex_val: str) -> str:
    """Converts #rrggbb → R,G,B — required by KColorScheme format."""
    hex_val = hex_val.lstrip("#")
    r, g, b = (int(hex_val[i : i + 2], 16) for i in (0, 2, 4))
    return f"{r},{g},{b}"


# ── Papirus color mapping ─────────────────────────────────────────────────────


def _hue_to_papirus_color(hue: float, pale: bool) -> str:
    """Maps HSV hue (0–360) to the closest Papirus folder color name."""
    if pale:
        if hue < 15 or hue >= 345:
            return "palered"
        if hue < 40:
            return "paleorange"
        if hue < 70:
            return "yellow"  # no pale yellow exists
        if hue < 150:
            return "palegreen"
        if hue < 195:
            return "paleteal"
        if hue < 220:
            return "palecyan"
        if hue < 265:
            return "breeze"  # closest pale blue
        if hue < 290:
            return "paleviolet"
        if hue < 320:
            return "palepurple"
        return "palepink"
    else:
        if hue < 15 or hue >= 345:
            return "red"
        if hue < 25:
            return "deeporange"
        if hue < 40:
            return "orange"
        if hue < 70:
            return "yellow"
        if hue < 150:
            return "green"
        if hue < 185:
            return "teal"
        if hue < 205:
            return "cyan"
        if hue < 255:
            return "blue"
        if hue < 275:
            return "indigo"
        if hue < 295:
            return "violet"
        if hue < 320:
            return "purple"
        return "pink"


# ── Config ───────────────────────────────────────────────────────────────────


@dataclass(frozen=True)
class NisfereConfig:
    """All filesystem paths the daemon touches, in one place."""

    nisfere_dir: Path = field(
        default_factory=lambda: Path("~/.config/nisfere").expanduser()
    )
    wallpapers_dir: Path = field(
        default_factory=lambda: Path("~/Pictures/Wallpapers").expanduser()
    )
    cache_dir: Path = field(
        default_factory=lambda: Path("~/.cache/nisfere").expanduser()
    )
    # ↓ External path – written by wallust, read by us
    wallust_colors_cache: Path = field(
        default_factory=lambda: Path("~/.cache/wallust/colors.json").expanduser()
    )
    wallust_config: Path = field(
        default_factory=lambda: Path("~/.config/wallust/wallust.toml").expanduser()
    )

    @property
    def templates_dir(self) -> Path:
        return self.nisfere_dir / "templates"

    @property
    def themes_dir(self) -> Path:
        return self.nisfere_dir / "themes"

    @property
    def template_map_path(self) -> Path:
        return self.nisfere_dir / "templates.json"

    @property
    def state_path(self) -> Path:
        return self.cache_dir / "state.json"


# ── State ────────────────────────────────────────────────────────────────────


@dataclass
class ThemeState:
    """
    Persisted state in ~/.cache/nisfere/state.json.

    source_type: "dynamic" → colors extracted from wallpaper via wallust
                 "static"  → colors loaded from a theme JSON file
    source_name: None if dynamic, the theme filename if static (e.g. "nord.json")
    colors:      flat dict passed to Jinja2; includes all color0-15, special,
                 computed (background_alt, border_color), wallpaper, mode, alpha
    """

    wallpaper: str
    mode: str  # "dark" | "light"
    source_type: str  # "dynamic" | "static"
    source_name: str | None
    colors: dict

    def to_dict(self) -> dict:
        return {
            "wallpaper": self.wallpaper,
            "mode": self.mode,
            "source_type": self.source_type,
            "source_name": self.source_name,
            "colors": self.colors,
        }

    @classmethod
    def from_dict(cls, data: dict) -> "ThemeState":
        return cls(
            wallpaper=data.get("wallpaper", ""),
            mode=data.get("mode", "dark"),
            source_type=data.get("source_type", "dynamic"),
            source_name=data.get("source_name"),
            colors=data.get("colors", {}),
        )


# ── Constants ─────────────────────────────────────────────────────────────────

_IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp", ".gif"}

# Injected into wallust.toml if the entry is missing
_WALLUST_TEMPLATE_ENTRY = (
    "wallust = { src = 'colors.json', dst = '~/.cache/wallust/colors.json' }"
)

# Written to templates.json on first run if the file doesn't exist
_DEFAULT_TEMPLATE_MAP: dict[str, str] = {
    "hyprland-colors.conf": "~/.config/hypr/conf/colors.conf",
    "alacritty-colors.toml": "~/.config/alacritty/colors.toml",
    "adw-gtk3.css": ["~/.config/gtk-3.0/gtk.css", "~/.config/gtk-4.0/gtk.css"],
    "thunar.css": ["~/.config/gtk-3.0/thunar.css", "~/.config/gtk-4.0/thunar.css"],
    "bpytop.theme": "~/.config/bpytop/themes/nisfere.theme",
    "vscode.json": "~/.cache/wallust/colors.json",
    "vscode": "~/.cache/wallust/colors",
    "nisfere.colors": "~/.config/qtengine/nisfere.colors",
}


# ── ThemeManager ──────────────────────────────────────────────────────────────


class ThemeManager:
    def __init__(self, config: NisfereConfig | None = None):
        self.config = config or NisfereConfig()

        self.env = Environment(undefined=StrictUndefined)
        self.env.filters["strip"] = filter_strip
        self.env.filters["lighten"] = filter_lighten
        self.env.filters["darken"] = filter_darken
        self.env.filters["rgb"] = filter_rgb

        self._ensure_dirs()
        self._ensure_wallust_template()
        self._template_map = self._load_template_map()

    # ── Setup ────────────────────────────────────────────────────────────────

    def _ensure_dirs(self) -> None:
        for d in (
            self.config.nisfere_dir,
            self.config.templates_dir,
            self.config.themes_dir,
            self.config.cache_dir,
        ):
            d.mkdir(parents=True, exist_ok=True)

    def _ensure_wallust_template(self) -> None:
        """
        Patches wallust.toml to include our colors.json template entry
        so wallust always exports colors where we expect them.
        """
        wt = self.config.wallust_config
        if not wt.exists():
            logger.warning("wallust.toml not found at %s — skipping template check", wt)
            return

        content = wt.read_text()
        if "colors.json" in content:
            logger.debug("wallust colors.json template already present")
            return

        if "[templates]" in content:
            content = content.replace(
                "[templates]",
                f"[templates]\n{_WALLUST_TEMPLATE_ENTRY}",
            )
        else:
            content += f"\n[templates]\n{_WALLUST_TEMPLATE_ENTRY}\n"

        wt.write_text(content)
        logger.info("Patched wallust.toml with colors.json template entry")

    def _load_template_map(self) -> dict[str, str]:
        """
        Loads ~/.config/nisfere/templates.json.
        Creates it with defaults if it doesn't exist.
        """
        p = self.config.template_map_path
        if not p.exists():
            logger.info("templates.json not found — creating with defaults at %s", p)
            p.write_text(json.dumps(_DEFAULT_TEMPLATE_MAP, indent=2))
            return dict(_DEFAULT_TEMPLATE_MAP)

        try:
            return json.loads(p.read_text())
        except json.JSONDecodeError as e:
            logger.error("templates.json is invalid (%s) — falling back to defaults", e)
            return dict(_DEFAULT_TEMPLATE_MAP)

    # ── Public API ───────────────────────────────────────────────────────────

    def toggle_mode(self):
        state = self.get_state()
        if not state:
            return {"success": False, "error": "No state found"}

        current_mode = state.get("mode", "dark")
        new_mode = "light" if current_mode == "dark" else "dark"

        logger.info(
            "[ThemeManager] Toggling mode from %s to %s", current_mode, new_mode
        )

        wp = state.get("wallpaper")
        source_type = state.get("source_type")
        source_name = state.get("source_name")

        success = False
        if source_type == "static" and source_name:
            success = self.set_colors(source_name, new_mode)
        elif wp:
            success = self.set_wallpaper(wp, True, new_mode)

        return {"success": success, "mode": new_mode}

    def preview_wallpaper(self, wallpaper_path: str) -> None:
        subprocess.run(
            ["awww", "img", wallpaper_path, "--transition-type", "none"],
            check=False,
        )

    def set_wallpaper(
        self, wallpaper_path: str, apply_colors: bool, mode: str = "dark"
    ) -> bool:
        subprocess.run(
            ["awww", "img", wallpaper_path, "--transition-type", "center"],
            check=False,
        )
        if apply_colors:
            colors_data = self._extract_dynamic_colors(wallpaper_path, mode)
            return self._apply_colors(
                colors_data,
                mode=mode,
                wallpaper_path=wallpaper_path,
                source_type="dynamic",
                source_name=None,
            )
        else:
            # Just update wallpaper field in existing state
            state = self._load_state()
            if state:
                state.wallpaper = wallpaper_path
                self._save_state(state)
            return True

    def set_colors(self, theme_name: str, mode: str = "dark") -> bool:
        colors_data = self._load_static_colors(theme_name, mode)
        state = self._load_state()
        wallpaper = state.wallpaper if state else ""
        return self._apply_colors(
            colors_data,
            mode=mode,
            wallpaper_path=wallpaper,
            source_type="static",
            source_name=theme_name,
        )

    def get_wallpapers(self) -> list[dict]:
        d = self.config.wallpapers_dir
        if not d.exists():
            logger.warning("Wallpapers directory not found: %s", d)
            return []
        return [
            {"name": p.stem, "path": str(p)}
            for p in sorted(d.iterdir())
            if p.is_file() and p.suffix.lower() in _IMAGE_EXTENSIONS
        ]

    def get_themes(self) -> list[dict]:
        """
        Returns unique theme base names, stripping -dark/-light suffixes.
        e.g. tokyo-night-dark.json + tokyo-night-light.json → [{name: "tokyo-night"}]
        The mode toggle in QuickShell determines which variant to load.
        """
        d = self.config.themes_dir
        if not d.exists():
            logger.warning("Themes directory not found: %s", d)
            return []

        seen: set[str] = set()
        result: list[dict] = []
        for p in sorted(d.iterdir()):
            if not p.is_file() or p.suffix != ".json":
                continue
            name = p.stem
            for suffix in ("-dark", "-light"):
                if name.endswith(suffix):
                    name = name[: -len(suffix)]
                    break
            if name not in seen:
                seen.add(name)
                result.append({"name": name})
        return result

    def get_state(self) -> dict | None:
        state = self._load_state()
        return state.to_dict() if state else None

    # ── State persistence ────────────────────────────────────────────────────

    def _load_state(self) -> ThemeState | None:
        try:
            data = json.loads(self.config.state_path.read_text())
            return ThemeState.from_dict(data)
        except FileNotFoundError:
            logger.debug("No state file yet at %s", self.config.state_path)
            return None
        except json.JSONDecodeError as e:
            logger.error("State file is corrupt: %s", e)
            return None

    def _save_state(self, state: ThemeState) -> None:
        self.config.state_path.write_text(json.dumps(state.to_dict(), indent=2))
        logger.debug("State saved → %s", self.config.state_path)

    # ── Core rendering ───────────────────────────────────────────────────────

    def _apply_colors(
        self,
        colors_data: dict,
        mode: str,
        wallpaper_path: str,
        source_type: str,
        source_name: str | None,
    ) -> bool:
        try:
            template_vars = self._prepare_template_vars(colors_data, mode)
            template_vars["wallpaper"] = wallpaper_path
            template_vars["mode"] = mode

            bg = template_vars["background"]
            template_vars["radius"] = 15  # used in templates for border-radius
            if mode == "light":
                template_vars["background_alt"] = filter_darken(bg, 0.05)
                template_vars["border_color"] = filter_darken(bg, 0.10)
            else:
                template_vars["background_alt"] = filter_lighten(bg, 0.05)
                template_vars["border_color"] = filter_lighten(bg, 0.10)

            self._render_all(template_vars)
            threading.Thread(
                target=self._sync_papirus_folders,
                args=(template_vars.get("color4", ""),),
                daemon=True,
            ).start()
            self._reload_system(mode)
            self._reload_system(mode)

            self._save_state(
                ThemeState(
                    wallpaper=wallpaper_path,
                    mode=mode,
                    source_type=source_type,
                    source_name=source_name,
                    colors=template_vars,
                )
            )

            logger.info(
                "Theme applied — mode=%s source=%s",
                mode,
                source_name or "dynamic",
            )
            return True

        except Exception as e:
            logger.error("Failed to apply theme: %s", e)
            return False

    def _sync_papirus_folders(self, accent_hex: str) -> None:
        """
        Recolors Papirus folder icons to match the current accent color.
        Requires: papirus-folders installed + papirus icon theme.
        Uses sudo -n (non-interactive) — add to sudoers if needed:
          username ALL=(ALL) NOPASSWD: /usr/bin/papirus-folders
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
                color = _hue_to_papirus_color(hue, pale)

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

    def _reload_system(self, mode: str = "dark") -> None:
        """
        Forces GTK3/4 apps to reload colors live.
        - Uses adw-gtk3 (no dark/light suffix) — our CSS variables handle colors
        - color-scheme tells GNOME apps the preference (prefer-dark / prefer-light)
        - Toggles gtk-theme (blank → name) to trigger CSS reload in all GTK apps
        - Restarts Thunar daemon so it picks up new thunar.css
        """

        def _run():
            try:
                # Always use base adw-gtk3 — CSS variables in gtk.css handle all colors.
                # dark/light variant is irrelevant since we override everything via @define-color.
                gtk_theme = "adw-gtk3-dark" if mode == "dark" else "adw-gtk3"

                # color-scheme: tells GNOME apps and portals the light/dark preference.
                # Colors themselves come from our rendered CSS, not from this setting.
                subprocess.run(
                    [
                        "gsettings",
                        "set",
                        "org.gnome.desktop.interface",
                        "color-scheme",
                        f"prefer-{mode}",
                    ],
                    check=False,
                )

                # Toggle blank → theme — triggers CSS reload in ALL running GTK apps
                subprocess.run(
                    [
                        "gsettings",
                        "set",
                        "org.gnome.desktop.interface",
                        "gtk-theme",
                        "",
                    ],
                    check=False,
                )
                subprocess.run(
                    [
                        "gsettings",
                        "set",
                        "org.gnome.desktop.interface",
                        "gtk-theme",
                        gtk_theme,
                    ],
                    check=False,
                )

                logger.debug("GTK reloaded (color-scheme=prefer-%s)", mode)
            except Exception as e:
                logger.warning("GTK reload failed: %s", e)

        threading.Thread(target=_run, daemon=True).start()

    def _extract_dynamic_colors(self, image_path: str, mode: str) -> dict:
        """Runs wallust on the image; reads the exported colors.json."""
        cmd = ["wallust", "run", os.path.expanduser(image_path)]
        if mode == "light":
            cmd.extend(["--palette", "light"])
        subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return json.loads(self.config.wallust_colors_cache.read_text())

    def _load_static_colors(self, theme_name: str, mode: str = "dark") -> dict:
        """
        Loads a color JSON from ~/.config/nisfere/themes/.
        Resolution order:
          1. {theme_name}-{mode}.json  (e.g. tokyo-night-dark.json)
          2. {theme_name}.json         (mode-agnostic fallback)
        """
        candidates = [
            self.config.themes_dir / f"{theme_name}-{mode}.json",
            self.config.themes_dir / f"{theme_name}.json",
        ]
        for path in candidates:
            if path.exists():
                logger.debug("Loading theme: %s", path.name)
                return json.loads(path.read_text())
        raise FileNotFoundError(
            f"Theme not found: '{theme_name}' (tried {[c.name for c in candidates]})"
        )

    def _prepare_template_vars(self, raw_data: dict, mode: str) -> dict:
        """Flattens wallust's nested JSON into a flat dict for Jinja2."""
        vars_dict: dict = {"mode": mode, "alpha": 100}

        # Top-level scalars (e.g. wallust's own alpha override)
        for k, v in raw_data.items():
            if not isinstance(v, dict):
                vars_dict[k] = v

        # special → background, foreground, cursor
        for k, v in raw_data.get("special", {}).items():
            vars_dict[k] = v

        # colors → color0 … color15
        for k, v in raw_data.get("colors", {}).items():
            vars_dict[k] = v

        return vars_dict

    def _render_all(self, template_vars: dict) -> None:
        """
        Renders every entry in templates.json and writes to its target path(s).
        Values in templates.json can be a single path (str) or multiple (list[str]).
        """
        failed: list[str] = []

        for template_name, target_paths in self._template_map.items():
            src = self.config.templates_dir / template_name

            if not src.exists():
                logger.warning("Template missing, skipping: %s", template_name)
                continue

            try:
                template = self.env.from_string(src.read_text())
                rendered = template.render(**template_vars)
            except Exception as e:
                logger.error("Failed to render %s: %s", template_name, e)
                failed.append(template_name)
                continue

            # Support single path (str) or multiple paths (list[str])
            if isinstance(target_paths, str):
                target_paths = [target_paths]

            for target_path in target_paths:
                dst = Path(target_path).expanduser()
                dst.parent.mkdir(parents=True, exist_ok=True)
                try:
                    # Direct write — preserves inode so GTK3 inotify watch works.
                    # GTK watches ~/.config/gtk-3.0/gtk.css by inode; atomic rename
                    # would change the inode and break the live reload watch.
                    dst.write_text(rendered)
                    logger.debug("Rendered %s → %s", template_name, dst)
                except Exception as e:
                    logger.error("Failed to write %s → %s: %s", template_name, dst, e)
                    failed.append(f"{template_name}→{dst.name}")

        if failed:
            raise RuntimeError(f"Render failed for: {failed}")
