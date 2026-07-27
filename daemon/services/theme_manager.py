"""
ThemeManager — orchestrates a theme change end to end:
  1. get raw colors from ColorSource (wallust or static json)
  2. merge them into StateManager's 'shared' scope
  3. re-render everything via TemplateRenderer
  4. trigger desktop side-effects via DesktopIntegration

It doesn't do any of steps 1-4 itself anymore. See:
  color_source.py, template_renderer.py, desktop_integration.py,
  state_manager.py
"""

import logging
import threading

from .config import NisfereConfig
from .color_source import ColorSource
from .color_utils import filter_darken, filter_lighten
from .desktop_integration import DesktopIntegration
from .state_manager import StateManager
from .template_renderer import TemplateRenderer

logger = logging.getLogger(__name__)

_IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp", ".gif"}

# Seeded into state.json on first daemon startup (see
# StateManager.seed_defaults) so these exist as real, editable values
# from day one — not just QML-side fallback constants nobody's ever
# confirmed are actually in effect.
_DEFAULT_SETTINGS: dict = {
    "shared": {
        "radius": 20,
        "fontName": "Arimo Nerd Font",
        "workspacesPerMonitor": 10
    },
    "shell": {
        "enableWidgetBorders": True,
        "barHeight": 50,
        "padding": 6,
        "panelBorderSize": 10,
        "widgetOpacity": 1.0,
    },
    "hyprland": {
        "workspaceGaps": 20,
        "windowGapsIn": 6,
        "windowGapsOut": 20,
        "windowBorderSize": 2,
        "opacityActive": 0.95,
        "opacityInactive": 0.85,
        "opacityFullscreen": 1.0,
        "blurEnabled": True,
        "blurSize": 8,
        "blurPasses": 3,
        "blurPopups": True,
        "shadowEnabled": True,
        "shadowRange": 15,
        "shadowRenderPower": 4,
        "cursorTheme": "Breeze-Adapta-Cursor",
        "cursorSize": 10,
    },
}


class ThemeManager:
    def __init__(self, config: NisfereConfig | None = None):
        self.config = config or NisfereConfig()
        self._ensure_dirs()

        self.colors = ColorSource(self.config)
        self.renderer = TemplateRenderer(
            self.config.templates_dir, self.config.template_map_path
        )
        self.desktop = DesktopIntegration()
        self.state = StateManager(self.config.state_path)
        self.state.seed_defaults(_DEFAULT_SETTINGS)

    def _ensure_dirs(self) -> None:
        for d in (
            self.config.nisfere_dir,
            self.config.templates_dir,
            self.config.themes_dir,
            self.config.cache_dir,
        ):
            d.mkdir(parents=True, exist_ok=True)

    # ── Public API ───────────────────────────────────────────────────────────

    def set_setting(self, key: str, value, scope: str = "shared") -> dict:
        """
        Updates ONE key in the given style scope (shared/shell/hyprland)
        and re-renders all templates so consumers see the change
        immediately.
        """
        try:
            state = self.state.set_setting(key, value, scope)
            self.renderer.render_all(state.style)
        except Exception as e:
            logger.error("Failed to re-render templates for setting '%s': %s", key, e)
            return {"success": False, "error": str(e)}

        logger.info("Setting updated: %s.%s = %r", scope, key, value)
        return {"success": True, "key": key, "value": value, "scope": scope}

    def toggle_mode(self) -> dict:
        state = self.state.load()
        if not state:
            return {"success": False, "error": "No state found"}

        new_mode = "light" if state.mode == "dark" else "dark"
        logger.info("Toggling mode from %s to %s", state.mode, new_mode)

        if state.source_type == "static" and state.source_name:
            success = self.set_colors(state.source_name, new_mode)
        elif state.wallpaper:
            success = self.set_wallpaper(state.wallpaper, True, new_mode)
        else:
            success = False

        return {"success": success, "mode": new_mode}

    def preview_wallpaper(self, wallpaper_path: str) -> None:
        self.desktop.preview_wallpaper(wallpaper_path)

    def set_wallpaper(
        self, wallpaper_path: str, apply_colors: bool, mode: str = "dark"
    ) -> bool:
        self.desktop.apply_wallpaper(wallpaper_path)

        if not apply_colors:
            # Just update wallpaper field in existing state.
            state = self.state.load()
            if state:
                state.wallpaper = wallpaper_path
                self.state.save(state)
            return True

        raw = self.colors.extract_dynamic(wallpaper_path, mode)
        return self._apply_colors(raw, mode, wallpaper_path, "dynamic", None)

    def set_colors(self, theme_name: str, mode: str = "dark") -> bool:
        raw = self.colors.load_static(theme_name, mode)
        state = self.state.load()
        wallpaper = state.wallpaper if state else ""
        return self._apply_colors(raw, mode, wallpaper, "static", theme_name)

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
        Returns unique theme base names (stripping -dark/-light
        suffixes) together with a color preview for each — read via
        the SAME ColorSource.load_static()/flatten() the daemon
        already uses when actually applying a theme, so the preview
        can never drift out of sync with reality.
        e.g. tokyo-night-dark.json + tokyo-night-light.json →
          [{"name": "tokyo-night", "colors": {...flattened dark palette...}}]
        Preview always reads the dark variant (falling back to light
        if no dark variant exists) regardless of the shell's current
        mode — just a representative swatch for a picker UI. The mode
        toggle still determines which variant actually gets applied.
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
            if name in seen:
                continue
            seen.add(name)

            preview: dict = {}
            for preview_mode in ("dark", "light"):
                try:
                    raw = self.colors.load_static(name, preview_mode)
                    preview = self.colors.flatten(raw, preview_mode)
                    break
                except FileNotFoundError:
                    continue
                except Exception as e:
                    logger.warning(
                        "Failed to read preview colors for theme '%s': %s", name, e
                    )
                    break

            result.append({"name": name, "colors": preview})
        return result

    def get_state(self) -> dict | None:
        state = self.state.load()
        return state.to_dict() if state else None

    # ── Internal ─────────────────────────────────────────────────────────────

    def _apply_colors(
        self,
        raw: dict,
        mode: str,
        wallpaper_path: str,
        source_type: str,
        source_name: str | None,
    ) -> bool:
        try:
            shared_vars = self.colors.flatten(raw, mode)
            shared_vars["wallpaper"] = wallpaper_path
            shared_vars["mode"] = mode

            bg = shared_vars["background"]
            if mode == "light":
                shared_vars["backgroundAlt"] = filter_darken(bg, 0.05)
                shared_vars["borderColor"] = filter_darken(bg, 0.10)
            else:
                shared_vars["backgroundAlt"] = filter_lighten(bg, 0.05)
                shared_vars["borderColor"] = filter_lighten(bg, 0.10)

            # Merges over existing 'shared' scope only — shell/hyprland
            # settings the user customized via set_setting() survive
            # untouched. This is the actual fix for the "wallpaper
            # change resets my settings" bug.
            state = self.state.update_shared(
                shared_vars, wallpaper_path, mode, source_type, source_name
            )

            self.renderer.render_all(state.style)

            # All desktop side-effect threading lives here, in one
            # place, instead of scattered across services.
            threading.Thread(
                target=self.desktop.sync_papirus_folders,
                args=(state.style.get("shared", {}).get("color4", ""),),
                daemon=True,
            ).start()
            threading.Thread(
                target=self.desktop.reload_gtk, args=(mode,), daemon=True
            ).start()

            logger.info(
                "Theme applied - mode=%s source=%s", mode, source_name or "dynamic"
            )
            return True

        except Exception as e:
            logger.error("Failed to apply theme: %s", e)
            return False
