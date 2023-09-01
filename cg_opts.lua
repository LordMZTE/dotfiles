local opts = {}

opts.mzteinit_entries = {
    { key = "x", label = "startx",   cmd = { "startx" } },
    { key = "s", label = "shell",    cmd = { "fish" } },
    { key = "l", label = "logout",   cmd = { "!quit" } },
    { key = "p", label = "shutdown", cmd = { "systemctl", "poweroff" }, quit = true },
    { key = "r", label = "reboot",   cmd = { "systemctl", "reboot" },   quit = true },
}

-- Enable if you have good internet, used for stuff like making
-- streamlink use low-latency mode.
opts.good_internet = true

-- Enable if stuck on garbage hardware. Enables wayland-related workarounds.
opts.nvidia = false

opts.font = "Iosevka Nerd Font"
opts.term_font = "IosevkaTerm Nerd Font Mono"

opts.term = {
    name = "Wezterm",
    command = "wezterm",
    workdir_command = "wezterm-gui start --cwd",
    icon_name = "org.wezfurlong.wezterm",
}

opts.cursor = {
    theme = "LyraQ-cursors",
    size = 24,
}

-- hwmon temperature path for CPU temp used by waybar
opts.cpu_temp_hwmon = "/sys/class/hwmon/hwmon0/temp1_input"

-- used in waybar config
opts.wayland_compositor = nil

opts.gtk_theme = "Catppuccin-Mocha-Standard-Red-dark"
opts.icon_theme = "candy-icons"

opts.commands = {
    browser = "openbrowser",
    email = "claws-mail",
    calculator = "qalculate-gtk",
    file_manager = "thunar",
    file_manager_daemon = "thunar --daemon",
    -- zenity-compatible dialoger
    zenity = "yad",
    notification_daemon = "wired",
    screen_lock = string.format("i3lock -ti %s/.local/share/backgrounds/mzte.png", os.getenv "HOME"),
}

opts.gamemode = {
    on_start = "notify-send 'Gamemode' 'Gamemode Active'",
    on_stop = "notify-send 'Gamemode' 'Gamemode Inactive'",
}

opts.dev_dir = os.getenv "HOME" .. "/dev"

return opts
