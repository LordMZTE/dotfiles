local opts = {}

opts.font = "Iosevka Nerd Font"
opts.term_font = "Iosevka Term Nerd Font Mono"

opts.term = {
    name = "Wezterm",
    command = "wezterm",
    workdir_command = "wezterm-gui start --cwd",
    icon_name = "org.wezfurlong.wezterm",
}

return opts
