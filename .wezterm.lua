local wezterm = require "wezterm"
local gitbash = {"C:\\Program Files\\Git\\bin\\bash.exe", "-i", "-l"}
return {
    color_scheme = "Dracula",
    default_prog = gitbash,
    keys = {
        {
            key = "F3",
            action = "ShowLauncher",
        },
        {
            key = "Y",
            mods = "CTRL",
            action = "Copy",
        },       
        {
            key = "C",
            mods = "CTRL",
            action = "DisableDefaultAssignment",
        },
        {
            key = " ",
            mods = "CTRL|SHIFT",
            action = "ActivateCopyMode",
        },
        {
            key = "9",
            mods = "ALT",
            action = "DisableDefaultAssignment",
        },
    },

    ssh_domains = {
        {
            name = "RPI",
            remote_address = "192.168.2.5",
            username = "pi",
        }
    },

    font_dirs = {"C:\\Windows\\Fonts"},

    font_rules = {
        {
            italic = false,
            bold = false,
            font = wezterm.font("Iosevka Nerd Font Complete"),
        },
        {
            italic = true,
            bold = false,
            font = wezterm.font("Iosevka Italic Nerd Font Complete"),
        },
        {
            italic = false,
            bold = true,
            font = wezterm.font("Iosevka Bold Nerd Font Complete"),
        },
        {
            italic = true,
            bold = true,
            font = wezterm.font("Iosevka Bold Italic Nerd Font Complete"),
        },
    },

    launch_menu = {
        {
            label = "Arch WSL",
            args = {"wsl", "-d", "Arch"},
        },
        {
            label = "Ubuntu WSL",
            args = {"wsl", "-d", "Ubuntu-20.04"},
        },
        {
            label = "Powershell",
            args = {"powershell"},
        },
        {
            label = "Git Bash",
            args = gitbash,
        },
    },
}
