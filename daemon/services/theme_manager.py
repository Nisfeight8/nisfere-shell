import os
import json
import subprocess
from jinja2 import Environment, StrictUndefined


# --- Custom Jinja2 Filters (Pure Python now!) ---
def filter_strip(hex_val):
    if isinstance(hex_val, str):
        return hex_val.lstrip("#")
    return hex_val


def filter_lighten(hex_val, amount=0.1):
    hex_val = hex_val.lstrip("#")
    rgb = [int(hex_val[i : i + 2], 16) for i in (0, 2, 4)]
    new_rgb = [min(255, int(c + (255 - c) * amount)) for c in rgb]
    return f"#{new_rgb[0]:02x}{new_rgb[1]:02x}{new_rgb[2]:02x}"


def filter_darken(hex_val, amount=0.1):
    hex_val = hex_val.lstrip("#")
    rgb = [int(hex_val[i : i + 2], 16) for i in (0, 2, 4)]
    new_rgb = [max(0, int(c * (1 - amount))) for c in rgb]
    return f"#{new_rgb[0]:02x}{new_rgb[1]:02x}{new_rgb[2]:02x}"


class ThemeManager:
    def __init__(self):
        self.cache_path = os.path.expanduser("~/.cache/nisfere/current_colors.json")
        self.nisfere_dir = os.path.expanduser("~/.config/nisfere")
        self.templates_dir = os.path.join(self.nisfere_dir, "templates")
        self.themes_dir = os.path.join(self.nisfere_dir, "themes")

        self.env = Environment(undefined=StrictUndefined)
        self.env.filters["strip"] = filter_strip
        self.env.filters["lighten"] = filter_lighten
        self.env.filters["darken"] = filter_darken

        self.template_map = {
            "hyprland-colors.conf": "~/.config/hypr/conf/colors.conf",
            "alacritty-colors.toml": "~/.config/alacritty/colors.toml",
            "gtk.css": "~/.themes/nisfere-gtk-theme/general/dark.css",
            "bpytop.theme": "~/.config/bpytop/themes/nisfere.theme",
            "vscode.json": "~/.cache/wallust/colors.json",
            "vscode": "~/.cache/wallust/colors",
        }

    def _apply_colors(self, colors_data: dict, mode: str, wallpaper_path: str = ""):
        template_vars = self._prepare_template_vars(colors_data, mode)
        try:
            if mode == "light":
                template_vars["background_alt"] = filter_darken(
                    template_vars["background"], 0.05
                )
                template_vars["border_color"] = filter_darken(
                    template_vars["background"], 0.10
                )
            else:
                template_vars["background_alt"] = filter_lighten(
                    template_vars["background"], 0.05
                )
                template_vars["border_color"] = filter_lighten(
                    template_vars["background"], 0.10
                )

            template_vars["wallpaper"] = wallpaper_path
            template_vars["mode"] = mode

            self._render_all(template_vars)

            os.makedirs(os.path.dirname(self.cache_path), exist_ok=True)
            with open(self.cache_path, "w") as f:
                json.dump(template_vars, f, indent=2)

            print("[ThemeManager] Cache + templates updated!")
            return True

        except Exception as e:
            print(f"[ThemeManager] Render Error: {e}")
            return False

    def preview_wallpaper(self, wallpaper_path):
        subprocess.run(
            ["awww", "img", wallpaper_path, "--transition-type", "none"], check=False
        )

    def set_wallpaper(
        self, wallpaper_path: str, apply_colors: bool, mode: str = "dark"
    ):
        subprocess.run(
            ["awww", "img", wallpaper_path, "--transition-type", "center"], check=False
        )
        if apply_colors:
            colors_data = self._extract_dynamic_colors(wallpaper_path, mode)
            self._apply_colors(colors_data, mode, wallpaper_path)
        else:
            try:
                with open(self.cache_path, "r") as f:
                    current = json.load(f)
                current["wallpaper"] = wallpaper_path
                with open(self.cache_path, "w") as f:
                    json.dump(current, f, indent=2)
            except (FileNotFoundError, json.JSONDecodeError):
                pass

        return True

    def set_colors(self, colors_json_path: str, mode: str = "dark"):
        colors_data = self._load_static_colors(colors_json_path, mode)
        try:
            with open(self.cache_path, "r") as f:
                current_wallpaper = json.load(f).get("wallpaper", "")
        except (FileNotFoundError, json.JSONDecodeError):
            current_wallpaper = ""

        return self._apply_colors(colors_data, mode, current_wallpaper)

    def _extract_dynamic_colors(self, image_path, mode):
        """Runs wallust ONLY to extract colors to JSON"""
        wallust_cache = os.path.expanduser("~/.cache/wallust/colors.json")

        cmd = ["wallust", "run", os.path.expanduser(image_path)]
        if mode == "light":
            cmd.extend(["--palette", "light16"])

        subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

        with open(wallust_cache, "r") as f:
            return json.load(f)

    def _load_static_colors(self, theme_name, mode):
        """Loads ready JSON from the nisfere/themes directory"""
        file_path = os.path.join(self.themes_dir, f"{theme_name}-{mode}.json")
        if not os.path.exists(file_path):
            raise FileNotFoundError(f"Theme file not found: {file_path}")
        with open(file_path, "r") as f:
            return json.load(f)

    def _prepare_template_vars(self, raw_data, mode):
        """Converts wallust's nested JSON into a flat dict for Jinja2"""
        # Default values (If dynamic, source is a path; if static, it's a name)
        vars_dict = {"mode": mode, "alpha": 100}

        # Read top-level variables from JSON (e.g., if Wallust set its own 'wallpaper' or 'alpha')
        for k, v in raw_data.items():
            if not isinstance(v, dict):
                vars_dict[k] = v

        # Add special (background, foreground)
        if "special" in raw_data:
            for k, v in raw_data["special"].items():
                vars_dict[k] = v

        # Add colors (color0 - color15)
        if "colors" in raw_data:
            for k, v in raw_data["colors"].items():
                vars_dict[k] = v

        return vars_dict

    def _render_all(self, template_vars):
        """Reads templates and writes the final files"""
        for template_name, target_path in self.template_map.items():
            src_file = os.path.join(self.templates_dir, template_name)
            dst_file = os.path.expanduser(target_path)

            if not os.path.exists(src_file):
                print(f"[ThemeManager] Warning: Template {template_name} is missing.")
                continue

            os.makedirs(os.path.dirname(dst_file), exist_ok=True)

            with open(src_file, "r") as f:
                # Load the template within our environment with our filters
                template = self.env.from_string(f.read())
            rendered = template.render(**template_vars)
            with open(dst_file, "w") as f:
                f.write(rendered)

    def _reload_system(self):
        """Executes live reload on WM and Panels"""
        # Reload Hyprland
        # subprocess.run(["hyprctl", "reload"], check=False)
        # Here you can send a signal to Quickshell or run: killall quickshell && quickshell &
        pass
