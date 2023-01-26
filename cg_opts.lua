local opts = {}

opts.font = "Iosevka Nerd Font"
opts.term_font = "Iosevka Term Nerd Font Mono"

opts.term = {
    name = "Wezterm",
    command = "wezterm",
    workdir_command = "wezterm-gui start --cwd",
    icon_name = "org.wezfurlong.wezterm",
}

opts.cursor_theme = "LyraQ-cursors"
opts.icon_theme = "candy-icons"

opts.commands = {
    browser = "openbrowser",
    email = "claws-mail",
    calculator = "qalculate-gtk",
    file_manager = "thunar",
}

return opts
