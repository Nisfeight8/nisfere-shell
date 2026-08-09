-- ~/.config/hypr/modules/group.lua
local vars = require("modules.variables")

hl.config({
    group = {
        auto_group = true,  -- windows only join a group when explicitly moved/dragged into one
        col = {
            border_active          = vars.active_border,
            border_inactive        = vars.inactive_border,
            border_locked_active   = vars.active_border,
            border_locked_inactive = vars.inactive_border,
        },
        groupbar = {
            font_family = vars.fontName,
            font_size   = 11,
            gradients   = true,
            height      = 22,
            text_color  = vars.fg_color,
            col = {
                active          = vars.active_border,
                inactive        = vars.inactive_border,
                locked_active   = vars.active_border,
                locked_inactive = vars.inactive_border,
            },
        },
    },
})