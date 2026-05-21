local cmd = require "lib.confgen.cmd"

cg.opt.mzteinit_entries = {
    -- TODO: the `which` invocations here are a workaround in case the relevant binaries
    -- are installed in a directory that mzteinit adds to $PATH, which it currently doesn't handle.
    { key = "z", label = "river",         cmd = { cg.opt.system "which mzteriver" } },
    { key = "u", label = "river-classic", cmd = { cg.opt.system "which mzteriver-classic" } },
    { key = "h", label = "hyprland",      cmd = { "Hyprland" } },
    { key = "n", label = "niri",          cmd = { "niri", "--session" } },
    { key = "s", label = "shell",         cmd = { "nu" } },
    { key = "l", label = "logout",        cmd = { "!quit" } },
    { key = "p", label = "shutdown",      cmd = { "systemctl", "poweroff" },                   quit = true },
    { key = "r", label = "reboot",        cmd = { "systemctl", "reboot" },                     quit = true },
}

-- Enable if you have good internet, used for stuff like making
-- streamlink use low-latency mode.
cg.opt.good_internet = true

-- Enable if stuck on garbage hardware. Enables wayland-related workarounds.
cg.opt.nvidia = false

cg.opt.font = "3270 Nerd Font"
cg.opt.term_font = "3270 Nerd Font Mono"
-- Font size multiplier. Useful for high-res displays.
cg.opt.font_size_mul = 1

cg.opt.mulFontSize = function(siz) return math.floor(siz * cg.opt.font_size_mul) end

-- Configurations for all terminals I tend to use. To activate one, set cg.opt.term to it.
cg.opt.terminal_configurations = {
    foot = {
        name = "foot",
        command = cmd.argv { "foot" },
        exec = cmd.argv { "foot" },
        workdir_command = cmd.argv { "foot", "--working-directory=" },
        icon_name = "foot",
    },
    ghostty = {
        name = "Ghostty",
        command = cmd.argv { "ghostty" },
        exec = cmd.argv { "ghostty", "-e" },
        workdir_command = cmd.argv { "ghostty", "--working-directory=" },
        icon_name = "com.mitchellh.ghostty",
    },
    kitty = {
        name = "Kitty",
        command = cmd.argv { "kitty" },
        exec = cmd.argv { "kitty" },
        workdir_command = cmd.argv { "kitty", "--working-directory=" },
        icon_name = "kitty",
    },
}

cg.opt.term = cg.opt.terminal_configurations.foot

cg.opt.cursor = {
    theme = "LyraQ-cursors",
    size = 24,
}

-- https://github.com/Fausto-Korpsvart/catppuccin-gtk-theme
cg.opt.gtk_theme = "Catppuccin-GTK-Red-Dark-Compact"
cg.opt.icon_theme = "candy-icons"

cg.opt.commands = {
    browser = cmd.argv { "openbrowser" },
    email = cmd.argv { "claws-mail" },
    calculator = cmd.argv { "qalculate-gtk" },
    file_manager = cmd.argv { "thunar" },
    -- zenity-compatible dialoger
    zenity = cmd.argv { "yad" },
    media = {
        volume_up = cmd.argv { "wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%+" },
        volume_down = cmd.argv { "wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%-" },
        mute_sink = cmd.argv { "wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle" },
        mute_source = cmd.argv { "wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle" },

        play_pause = cmd.argv { "playerctl", "play-pause" },
        stop = cmd.argv { "playerctl", "stop" },
        next = cmd.argv { "playerctl", "next" },
        prev = cmd.argv { "playerctl", "previous" },
    },
    backlight_up = cmd.argv { "brightnessctl", "s", "15%+" },
    backlight_down = cmd.argv { "brightnessctl", "s", "15%-" },
}

cg.opt.gamemode = {
    on_start = cmd.argv { "notify-send", "-a", "Gamemode", "Gamemode Active" },
    on_stop = cmd.argv { "notify-send", "-a", "Gamemode", "Gamemode Inactive" },
}

cg.opt.dev_dir = os.getenv "HOME" .. "/dev"

cg.opt.irc = {
    nick = "lordmzte",
    realname = "LordMZTE",
}

cg.opt.matrix = {
    mxid = "@lordmzte:mzte.de",
}

cg.opt.keyboard = {
    layout = "de",
    options = {
        -- you could add, for example { "caps:swapescape" }
        "compose:menu",
    },
}

local ctp_rgb = {}
setmetatable(ctp_rgb, {
    __index = function(_, key)
        local hex = cg.opt.catppuccin[key]
        if not hex then return nil end
        local rs, gs, bs = string.match(hex, "^(%x%x)(%x%x)(%x%x)$")
        return {
            r = tonumber(rs, 16),
            g = tonumber(gs, 16),
            b = tonumber(bs, 16),
        }
    end,
})
cg.opt.catppuccin = {
    rgb = ctp_rgb,

    base = "1e1e2e",
    blue = "89b4fa",
    crust = "11111b",
    flamingo = "f2cdcd",
    green = "a6e3a1",
    lavender = "b4befe",
    mantle = "181825",
    maroon = "eba0ac",
    mauve = "cba6f7",
    overlay0 = "6c7086",
    overlay1 = "7f849c",
    overlay2 = "9399b2",
    peach = "fab387",
    pink = "f5c2e7",
    red = "f38ba8",
    rosewater = "f5e0dc",
    sapphire = "74c7ec",
    sky = "89dceb",
    subtext0 = "a6adc8",
    subtext1 = "bac2de",
    surface0 = "313244",
    surface1 = "45475a",
    surface2 = "585b70",
    teal = "94e2d5",
    text = "cdd6f4",
    yellow = "f9e2af",
}

cg.opt.homepage_url = "file://" .. os.getenv "HOME" .. "/confgenfs/cgassets/homepage.html"

cg.opt.cgpath = cg.fs and cg.fs.mountpoint or require("lfs").currentdir() .. "/cgout"

cg.opt.textwidth = 100

-- The size to use when downloading or streaming videos. Typically, only the height is checked here.
cg.opt.videosize = { 1920, 1080 }
