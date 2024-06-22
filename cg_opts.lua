local opts = {}

opts.mzteinit_entries = {
    -- TODO: the `which` invocations here are a workaround in case the relevant binaries
    -- are installed in a directory that mzteinit adds to $PATH, which it currently doesn't handle.
    { key = "z", label = "river",    cmd = { cg.opt.system "which mzteriver" } },
    { key = "h", label = "hyprland", cmd = { "Hyprland" } },
    { key = "s", label = "shell",    cmd = { cg.opt.system "which nu" } },
    { key = "l", label = "logout",   cmd = { "!quit" } },
    { key = "p", label = "shutdown", cmd = { "systemctl", "poweroff" }, quit = true },
    { key = "r", label = "reboot",   cmd = { "systemctl", "reboot" },   quit = true },
}

-- Enable if you have good internet, used for stuff like making
-- streamlink use low-latency mode.
opts.good_internet = true

-- Enable if stuck on garbage hardware. Enables wayland-related workarounds.
opts.nvidia = false

opts.font = "Iosevka NF"
opts.term_font = "IosevkaTerm NFM"

--opts.term = {
--    name = "Wezterm",
--    command = "wezterm",
--    workdir_command = "wezterm-gui start --cwd ",
--    icon_name = "org.wezfurlong.wezterm",
--}

--opts.term = {
--    name = "Ghostty",
--    command = "ghostty",
--    workdir_command = "ghostty --working-directory=",
--    icon_name = "com.mitchellh.ghostty",
--}

opts.term = {
    name = "foot",
    command = "foot",
    workdir_command = "foot --working-directory=",
    icon_name = "foot",
}

opts.cursor = {
    theme = "LyraQ-cursors",
    size = 24,
}

-- hwmon temperature path for CPU temp used by waybar
opts.cpu_temp_hwmon = "/sys/class/hwmon/hwmon0/temp1_input"

opts.gtk_theme = "catppuccin-mocha-red-standard+default"
opts.icon_theme = "candy-icons"

opts.commands = {
    browser = "openbrowser",
    email = "claws-mail",
    calculator = "qalculate-gtk",
    file_manager = "thunar",
    file_manager_daemon = "thunar --daemon",
    -- zenity-compatible dialoger
    zenity = "yad",
    notification_daemon = {
        x = "wired",
        wl = "mako",
    },
    screen_lock = string.format("i3lock -ti %s/.local/share/backgrounds/mzte.png", os.getenv "HOME"),
    media = {
        volume_up = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+",
        volume_down = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-",
        mute_sink = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle",
        mute_source = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle",

        play_pause = "playerctl play-pause",
        stop = "playerctl stop",
        next = "playerctl next",
        prev = "playerctl previous",
    },
}

opts.gamemode = {
    on_start = "notify-send 'Gamemode' 'Gamemode Active'",
    on_stop = "notify-send 'Gamemode' 'Gamemode Inactive'",
}

opts.dev_dir = os.getenv "HOME" .. "/dev"

opts.catppuccin = {
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

return opts
