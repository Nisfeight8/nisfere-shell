import asyncio
from services.theme_manager import ThemeManager

# We create the object once when the module loads
theme_manager = ThemeManager()


async def handle_command(action, payload, sock):
    if action == "set_wallpaper":
        wallpaper_path = payload.get("wallpaper_path")
        apply_colors = payload.get("apply_colors", True)
        mode = payload.get("mode", "dark")

        success = await asyncio.to_thread(
            theme_manager.set_wallpaper, wallpaper_path, apply_colors, mode
        )
        await sock.send(
            {
                "type": "theme_applied",
                "payload": {"success": success, "wallpaper": wallpaper_path},
            }
        )

    elif action == "set_colors":
        colors_json_path = payload.get("colors_json_path")
        mode = payload.get("mode", "dark")

        success = await asyncio.to_thread(
            theme_manager.set_colors, colors_json_path, mode
        )
        await sock.send({"type": "theme_applied", "payload": {"success": success}})

    elif action == "preview_wallpaper":
        wallpaper_path = payload.get("wallpaper_path")
        if wallpaper_path:
            await asyncio.to_thread(
                theme_manager.preview_wallpaper, wallpaper_path
            )
        return
