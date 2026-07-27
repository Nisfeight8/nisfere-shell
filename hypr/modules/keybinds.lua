-- ~/.config/hypr/keybinds.lua
-- Full translation of the old hyprlang binds + new shell IPC handlers.
--
-- CONFLICT FOUND in your old .conf: `$mainMod, S` was bound to BOTH
-- togglefloating AND togglespecialworkspace("magic") — in hyprlang the
-- later one wins, so togglefloating probably never actually fired.
-- I moved togglefloating to SUPER+V (and Firefox to SUPER+SHIFT+V) —
-- change this if you'd rather keep S for floating and rebind the
-- scratchpad elsewhere.

local mainMod = "SUPER"
local terminal = "alacritty"        -- set to your $terminal
local fileManager = "thunar"    -- set to your $fileManager

-- ═══════════════════════════════════════════════════════════════════
-- CORE WINDOW / SESSION
-- ═══════════════════════════════════════════════════════════════════
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q",      hl.dsp.window.close())
hl.bind(mainMod .. " + E",      hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + F",      hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(mainMod .. " + V",      hl.dsp.window.float())  -- was S (conflict, see note above)


hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("hyprshutdown"))

-- Firefox — moved to B (Browser) since V/SHIFT+V are now float-toggle
-- and clipboard respectively
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("firefox"))

-- pseudo (dwindle only) — was commented out in your old conf, kept the same
-- hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())

-- ═══════════════════════════════════════════════════════════════════
-- YOUR SHELL — replaces the old init-panel.sh / $panel calls
-- ═══════════════════════════════════════════════════════════════════
-- Tap SUPER alone (press+release, no other key) to open the launcher —
-- doesn't conflict with SUPER+X binds since it needs a bare release.
-- Extra convenience alongside SUPER+R below, not a replacement.
hl.bind(mainMod .. " + SUPER_L", hl.dsp.exec_cmd("qs ipc call launcher toggle"), { release = true })

hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("qs ipc call launcher toggle"))     -- was: exec init-panel.sh
hl.bind(mainMod .. " + X", hl.dsp.exec_cmd("qs ipc call powermenu toggle"))    -- was: $panel launcher.open('power_menu')
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("qs ipc call quickactions toggle colors"))  -- was: theme_switcher_menu

-- Was `$mainMod, SPACE, exec, $menu` — this looked like a SECOND,
-- separate app-launcher binding alongside R's init-panel.sh. Since R
-- now opens your Quickshell launcher, I pointed SPACE at the same
-- thing (redundant-but-harmless second shortcut) — tell me if you
-- actually wanted a DIFFERENT launcher (e.g. plain rofi/wofi) here
-- instead.
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("qs ipc call launcher toggle"))

-- New — workspace overview grid (wasn't bound to anything before)
hl.bind(mainMod .. " + Tab", hl.dsp.exec_cmd("qs ipc call overview toggle"))

-- New — screen lock (replaces the XF86Lock -> swaylock bind further down)
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("qs ipc call nisfere-lock trigger"))

-- New — dashboard / control center (weren't bound before; pick keys you like)
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("qs ipc call dashboard toggle"))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("qs ipc call controlcenter toggle"))

-- New — screenshot now goes through your ScreenshotService (countdown
-- OSD, mode picker) instead of raw grim. Screen record wasn't bound
-- before at all.
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("qs ipc call quickactions toggle screenshot"))
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("qs ipc call quickactions toggle recorder"))

-- New — wallpaper picker (wasn't bound before)
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("qs ipc call quickactions toggle wallpaper"))

-- New — clipboard manager (wasn't bound before)
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("qs ipc call quickactions toggle clipboard"))

-- New — color picker (eyedropper). Not one of the quickAction panels
-- (screenshot/recorder/wallpaper/colors/clipboard) — it's a standalone
-- fire-and-forget action inside your QuickActionsBar itself, so this
-- calls hyprpicker directly, matching what that button already does
-- internally, rather than routing through "open".
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd(
    "hyprpicker -f hex | wl-copy && notify-send 'Color picked' \"$(wl-paste)\" -a color-picker"
))

-- New — direct suspend (previously only reachable via the PowerMenu UI)
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.exec_cmd("systemctl suspend"), { locked = true })

-- ═══════════════════════════════════════════════════════════════════
-- FOCUS MOVEMENT
-- ═══════════════════════════════════════════════════════════════════
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- ═══════════════════════════════════════════════════════════════════
-- MOVE WINDOW (swap position) — SHIFT+arrows
-- ═══════════════════════════════════════════════════════════════════
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down" }))

-- ═══════════════════════════════════════════════════════════════════
-- RESIZE — Minus/Equal. UNVERIFIED table
-- ═══════════════════════════════════════════════════════════════════
hl.bind(mainMod .. " + Minus",       hl.dsp.window.resize({ x = -10, y = 0 }),  { repeating = true })
hl.bind(mainMod .. " + Equal",       hl.dsp.window.resize({ x = 10,  y = 0 }),  { repeating = true })
hl.bind(mainMod .. " + SHIFT + Minus", hl.dsp.window.resize({ x = 0, y = -10 }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + Equal", hl.dsp.window.resize({ x = 0, y = 10 }), { repeating = true })

-- ═══════════════════════════════════════════════════════════════════
-- WORKSPACES 1-10 + move window to workspace
-- ═══════════════════════════════════════════════════════════════════
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- next/prev workspace across ALL monitors ("m+1"/"m-1" — matches the
-- monitor-relative convention the official example uses for scroll
-- with "e+1"/"e-1"; UNVERIFIED for the "m" prefix specifically, the
-- example only demonstrated "e").
--
-- NOTE: this COLLIDES with the Overview bind on SUPER+Tab above —
-- pick ONE. I moved this pair to bracket keys instead so both work:
hl.bind(mainMod .. " + bracketright", hl.dsp.focus({ workspace = "m+1" }))
hl.bind(mainMod .. " + bracketleft",  hl.dsp.focus({ workspace = "m-1" }))

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through workspaces with mainMod + wheel
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows by dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- ═══════════════════════════════════════════════════════════════════
-- MEDIA / VOLUME / BRIGHTNESS — unchanged from your old conf
-- ═══════════════════════════════════════════════════════════════════
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"),  { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),  { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl s 10%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 10%-"), { locked = true, repeating = true })

-- Uses your shell's own MediaService (target: "mpris") instead of raw
-- playerctl — this gets you the smart "active player" selection logic
-- (prioritizes whichever player is ACTUALLY playing, not just whatever
-- happens to be first in the list) that we fixed earlier, rather than
-- whatever playerctl picks on its own.
--
-- XF86AudioPlay and XF86AudioPause both map to playPause (toggle) —
-- matches your old conf, where BOTH keys called `playerctl play-pause`
-- rather than separate play-only/pause-only actions (some keyboards
-- report one or the other for the same physical button).
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("qs ipc call mpris next"),     { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("qs ipc call mpris playPause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("qs ipc call mpris playPause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("qs ipc call mpris previous"), { locked = true })

-- Function-key duplicates of the above (F2/F3/F4, F6/F7/F8) — kept
-- identical to your old conf, requires playerctl for F6-F8
hl.bind("F3", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("F2", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("F4", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })

hl.bind("F8", hl.dsp.exec_cmd("qs ipc call mpris next"),     { locked = true })
hl.bind("F7", hl.dsp.exec_cmd("qs ipc call mpris playPause"), { locked = true })
hl.bind("F6", hl.dsp.exec_cmd("qs ipc call mpris previous"), { locked = true })