"""
ColorSource — knows how to GET raw color data and flatten it into
template-ready vars. Doesn't know about templates.json, doesn't touch
state.json, doesn't talk to the desktop. Just: image/theme in, flat
color dict out.
"""

import json
import logging
import os
import subprocess

from .config import NisfereConfig

logger = logging.getLogger(__name__)

# Injected into wallust.toml if the entry is missing
_WALLUST_TEMPLATE_ENTRY = (
    "wallust = { src = 'colors.json', dst = '~/.cache/wallust/colors.json' }"
)


class ColorSource:
    def __init__(self, config: NisfereConfig):
        self.config = config
        self._ensure_wallust_template()

    # ── Setup ────────────────────────────────────────────────────────────────

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

    # ── Sources ──────────────────────────────────────────────────────────────

    def extract_dynamic(self, image_path: str, mode: str) -> dict:
        """Runs wallust on the image; reads the exported colors.json."""
        cmd = ["wallust", "run", os.path.expanduser(image_path)]
        if mode == "light":
            cmd.extend(["--palette", "light"])
        subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return json.loads(self.config.wallust_colors_cache.read_text())

    def load_static(self, theme_name: str, mode: str = "dark") -> dict:
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

    # ── Shaping ──────────────────────────────────────────────────────────────

    def flatten(self, raw_data: dict, mode: str) -> dict:
        """
        Flattens wallust's nested JSON (special/colors) into a flat
        dict of template vars. Everything this returns belongs in the
        'shared' style scope — colors are the one thing both Quickshell
        and Hyprland always need.
        """
        vars_dict: dict = {"mode": mode, "alpha": 100}

        for k, v in raw_data.items():
            if not isinstance(v, dict):
                vars_dict[k] = v

        for k, v in raw_data.get("special", {}).items():
            vars_dict[k] = v

        for k, v in raw_data.get("colors", {}).items():
            vars_dict[k] = v

        return vars_dict
