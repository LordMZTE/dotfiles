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
