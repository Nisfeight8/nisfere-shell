"""
StateManager — owns ~/.cache/nisfere/state.json exclusively.

style is split into three explicit scopes instead of one flat
namespace, matching who actually reads what:

  shared:   colorN, background, foreground, cursor, radius, fontName —
            anything both Quickshell (bar/widgets) and Hyprland need.
  shell:    Quickshell-only knobs (barHeight, widgetOpacity, ...).
  hyprland: Hyprland-only knobs (gaps, blur, shadow, cursor size, ...).

ThemeManager (and anything else) should go THROUGH this rather than
touching state.json directly — this is the only class that reads or
writes that file.
"""

import json
import logging
from dataclasses import dataclass, field
from pathlib import Path

logger = logging.getLogger(__name__)

_SCOPES = ("shared", "shell", "hyprland")

# nisfere_chroma.py's own tuning knobs — kept as its own top-level
# dict, NOT inside style/shared/shell/hyprland, since these affect
# HOW colors get extracted, not the resulting visual style itself.
# No template ever reads these.
_DEFAULT_CHROMA_SETTINGS = {
    "algorithm": "median_cut",
    "saturation": 1.3,
    "bg_saturation": 0.08,
    "contrast": 1.0,
    "resize_to": 200,
}

# Keys that lived in the OLD flat style dict and are Hyprland- or
# shell-only. Used ONLY once, to bucket a pre-existing flat
# state.json the first time it's loaded after upgrading. Anything
# not listed here defaults to "shared" — the safe choice, since it
# keeps colors and any future/unknown key visible to both consumers
# instead of silently dropping it from one of them.
_HYPRLAND_ONLY_KEYS = {
    "workspaceGaps", "windowGapsIn", "windowGapsOut", "windowBorderSize",
    "opacityActive", "opacityInactive", "opacityFullscreen",
    "blurEnabled", "blurSize", "blurPasses", "blurPopups",
    "shadowEnabled", "shadowRange", "shadowRenderPower",
    "cursorTheme", "cursorSize",
}
_SHELL_ONLY_KEYS = {
    "enableWidgetBorders", "barHeight", "padding", "panelBorderSize", "widgetOpacity",
}


def _migrate_flat_style(flat: dict) -> dict:
    """One-time bucketing of a pre-refactor flat style dict into the
    new shared/shell/hyprland scopes."""
    bucketed: dict = {"shared": {}, "shell": {}, "hyprland": {}}
    for key, value in flat.items():
        if key in _HYPRLAND_ONLY_KEYS:
            bucketed["hyprland"][key] = value
        elif key in _SHELL_ONLY_KEYS:
            bucketed["shell"][key] = value
        else:
            bucketed["shared"][key] = value
    if flat:
        logger.info(
            "Migrated flat state.json style dict into shared/shell/hyprland scopes"
        )
    return bucketed


@dataclass
class ThemeState:
    """
    ...
    chroma_settings: tuning knobs for nisfere_chroma.py's own
                 extract_palette() (algorithm, saturation, etc.) — see
                 _DEFAULT_CHROMA_SETTINGS above.
    style:       {"shared": {...}, "shell": {...}, "hyprland": {...}}
    """

    wallpaper: str
    mode: str
    source_type: str
    source_name: str | None
    chroma_settings: dict = field(
        default_factory=lambda: dict(_DEFAULT_CHROMA_SETTINGS)
    )
    style: dict = field(
        default_factory=lambda: {"shared": {}, "shell": {}, "hyprland": {}}
    )

    def to_dict(self) -> dict:
        return {
            "wallpaper": self.wallpaper,
            "mode": self.mode,
            "source_type": self.source_type,
            "source_name": self.source_name,
            "chroma_settings": self.chroma_settings,
            "style": self.style,
        }

    @classmethod
    def from_dict(cls, data: dict) -> "ThemeState":
        style = data.get("style", {})
        if not any(scope in style for scope in _SCOPES):
            style = _migrate_flat_style(style)
        else:
            for scope in _SCOPES:
                style.setdefault(scope, {})

        # Missing chroma_settings (or missing individual keys within
        # it — e.g. upgrading from before a new knob was added) fall
        # back to defaults, same "fill gaps, never overwrite" spirit
        # as seed_defaults() below.
        chroma_settings = dict(_DEFAULT_CHROMA_SETTINGS)
        chroma_settings.update(data.get("chroma_settings", {}))

        return cls(
            wallpaper=data.get("wallpaper", ""),
            mode=data.get("mode", "dark"),
            source_type=data.get("source_type", "dynamic"),
            source_name=data.get("source_name"),
            chroma_settings=chroma_settings,
            style=style,
        )

class StateManager:
    """The ONLY class that reads or writes state.json."""

    def __init__(self, state_path: Path):
        self.state_path = state_path

    # ── Core I/O ─────────────────────────────────────────────────────────

    def load(self) -> ThemeState | None:
        try:
            data = json.loads(self.state_path.read_text())
            return ThemeState.from_dict(data)
        except FileNotFoundError:
            logger.debug("No state file yet at %s", self.state_path)
            return None
        except json.JSONDecodeError as e:
            logger.error("State file is corrupt: %s", e)
            return None

    def save(self, state: ThemeState) -> None:
        self.state_path.parent.mkdir(parents=True, exist_ok=True)
        self.state_path.write_text(json.dumps(state.to_dict(), indent=2))
        logger.debug("State saved -> %s", self.state_path)

    def _load_or_new(self) -> ThemeState:
        return self.load() or ThemeState(
            wallpaper="", mode="dark", source_type="dynamic", source_name=None
        )

    # ── Single-setting access (for a future settings UI) ───────────────────

    def get_setting(self, key: str, scope: str | None = None, default=None):
        """
        Reads ANY key from the style namespace — not restricted to a
        fixed whitelist, so a future settings UI can read/write
        arbitrary keys without this class needing changes per key.

        If `scope` is given, looks only there. Otherwise checks
        shared -> shell -> hyprland in that order and returns the
        first match.
        """
        state = self.load()
        if not state:
            return default
        scopes = (scope,) if scope else _SCOPES
        for s in scopes:
            bucket = state.style.get(s, {})
            if key in bucket:
                return bucket[key]
        return default

    def set_setting(self, key: str, value, scope: str = "shared") -> ThemeState:
        """Updates ONE key in the given scope, preserving everything else."""
        if scope not in _SCOPES:
            raise ValueError(f"Invalid scope '{scope}', must be one of {_SCOPES}")
        state = self._load_or_new()
        state.style.setdefault(scope, {})[key] = value
        self.save(state)
        return state

    def get_chroma_settings(self) -> dict:
        state = self.load()
        return dict(state.chroma_settings) if state else dict(_DEFAULT_CHROMA_SETTINGS)

    def set_chroma_setting(self, key: str, value) -> ThemeState:
        """Updates ONE chroma extraction setting, preserving everything else."""
        state = self._load_or_new()
        state.chroma_settings[key] = value
        self.save(state)
        return state

    # ── Bulk color/theme updates (wallpaper change, theme switch) ───────────

    def update_shared(
        self,
        new_values: dict,
        wallpaper: str,
        mode: str,
        source_type: str,
        source_name: str | None,
    ) -> ThemeState:
        """
        Merges new_values OVER the existing 'shared' scope ONLY —
        shell and hyprland settings (set via set_setting) are left
        completely untouched. This is the fix for the bug where
        changing wallpaper/theme used to reset general settings back
        to hardcoded defaults: a color/theme change now only ever
        touches the shared bucket, by construction.
        """
        existing = self.load()
        style = {
            "shared": dict(existing.style.get("shared", {})) if existing else {},
            "shell": dict(existing.style.get("shell", {})) if existing else {},
            "hyprland": dict(existing.style.get("hyprland", {})) if existing else {},
        }
        style["shared"].update(new_values)

        state = ThemeState(
            wallpaper=wallpaper,
            mode=mode,
            source_type=source_type,
            source_name=source_name,
            style=style,
            chroma_settings=dict(existing.chroma_settings) if existing else dict(_DEFAULT_CHROMA_SETTINGS),
        )
        self.save(state)
        return state

    # ── Seed defaults ────────────────────────────────────────────────────

    def seed_defaults(self, defaults: dict) -> None:
        """
        defaults: {"shared": {...}, "shell": {...}, "hyprland": {...}}

        Ensures every key in each scope actually EXISTS in state.json,
        writing it in if missing (never overwrites a key already
        there). Call once at daemon startup.
        """
        state = self._load_or_new()
        added: dict[str, list[str]] = {}

        for scope in _SCOPES:
            bucket = state.style.setdefault(scope, {})
            for key, value in defaults.get(scope, {}).items():
                if key not in bucket:
                    bucket[key] = value
                    added.setdefault(scope, []).append(key)

        if added:
            self.save(state)
            logger.info("Seeded missing default settings into state.json: %s", added)
