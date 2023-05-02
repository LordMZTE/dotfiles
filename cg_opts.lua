local opts = {}

-- Enable if you have good internet, used for stuff like making
-- streamlink use low-latency mode.
opts.good_internet = true

opts.font = "Iosevka Nerd Font"
opts.term_font = "Iosevka Nerd Font"

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

opts.icon_theme = "candy-icons"

opts.commands = {
    browser = "openbrowser",
    email = "claws-mail",
    calculator = "qalculate-gtk",
    file_manager = "thunar",
    file_manager_daemon = "thunar --daemon",
    -- zenity-compatible dialoger
    zenity = "yad",
}

-- Device temperature levels. Used for status bar.
opts.temperatures = {
    normal = 40,
    medium = 65,
    high = 80,
}

return opts
