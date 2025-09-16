-- Common data shared among window managers.
-- Window managers/Compositors implementing this:
-- - Hyprland
-- - River (via MZTERiver)
-- - Niri

local mod_shorthands = {
    m = "meta",
    s = "shift",
    c = "ctrl",
    a = "alt",
}

-- Shorthand to convert a string with single-char key modifiers to a key modifier table.
local function kmods(str)
    local modtable = {}
    str:gsub(".", function(c)
        local kmod = mod_shorthands[c]
        if kmod then
            table.insert(modtable, kmod)
        end
    end)
    return modtable
end

local mod = {}

-- Keybinds in this section are expressed as tuples with a list of modifiers from `mod_shorthands`
-- and an XKB key.

-- This is a table of control-level keybinds that should be implemented on all WMs.
-- Due to the fact that all WMs do this differently, an added value here needs to be
-- reflected on all implementors.
--
-- Additionally to these keys here, a WM must implement directionaly keys with meta+HJKL and arrow
-- keys as well as workspace keys with meta and numbers. Due to how different layout strategies make
-- for different setups here, this is to be defined separately for each compositor.
mod.control_keys = {
    quit = { kmods "ms", "E" },
    close_window = { kmods "ms", "Q" },
    float = { kmods "m", "Space" },
    fullscreen = { kmods "ms", "F" },
}

local cmds = cg.opt.commands

-- Keys that start some command expressed in shell notation.
mod.launch_keys = {
    -- Media Keys
    [{ {}, "XF86AudioRaiseVolume" }] = cmds.media.volume_up,
    [{ {}, "XF86AudioLowerVolume" }] = cmds.media.volume_down,
    [{ {}, "XF86AudioMute" }] = cmds.media.mute_sink,
    [{ {}, "XF86AudioMicMute" }] = cmds.media.mute_source,
    [{ {}, "XF86AudioPlay" }] = cmds.media.play_pause,
    [{ {}, "XF86AudioStop" }] = cmds.media.stop,
    [{ {}, "XF86AudioNext" }] = cmds.media.next,
    [{ {}, "XF86AudioPrev" }] = cmds.media.prev,
    [{ {}, "XF86Eject" }] = "eject -T",

    -- Backlight Keys
    [{ {}, "XF86MonBrightnessUp" }] = cmds.backlight_up,
    [{ {}, "XF86MonBrightnessDown" }] = cmds.backlight_down,

    -- Screenshot
    [{ {}, "Print" }] = [[grim -g "$(slurp; sleep 1)" - | satty --filename -]],

    -- Background controls
    [{ kmods "m", "W" }] = "pkill -USR1 wlbg",  -- Randomize background
    [{ kmods "ms", "W" }] = "pkill -USR2 wlbg", -- Toggle solid background

    -- Safe mode
    [{ kmods "m", "S" }] = [[echo "cg.opt.toggleSafeMode()" > ~/confgenfs/_cgfs/eval]],

    -- Application Launchers
    [{ kmods "m", "Return" }] = cg.opt.term.command,
    [{ kmods "a", "Space" }] = "rofi -show combi",
    [{ kmods "ma", "Space" }] = "rofi -show emoji",
    [{ kmods "mc", "E" }] = cmds.file_manager,
    [{ kmods "mc", "B" }] = cmds.browser,
    [{ kmods "mc", "V" }] = "vinput",
}

return mod
