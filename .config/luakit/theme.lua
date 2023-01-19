local dracula = {
    bg = "#282a36",
    fg = "#f8f8f2",
    bright_bg = "#44475a",
    very_bright_bg = "#6272a4",
    cyan = "#8be9fd",
    green = "#50fa7b",
    orange = "#ffb86c",
    pink = "#ff79c6",
    purple = "#bd93f9",
    red = "#ff5555",
    yellow = "#f1fa8c",
}

local theme = {}

-- Default settings
theme.font = "12px Iosevka Nerd Font"
theme.fg = dracula.fg
theme.bg = dracula.bg

-- Genaral colors
theme.success_fg = dracula.green
theme.loaded_fg = dracula.cyan

-- Error colors
theme.error_fg = dracula.red
theme.error_bg = dracula.bright_bg

-- Warning colors
theme.warning_fg = dracula.orange
theme.warning_bg = dracula.bright_bg

-- Notification colors
theme.notif_fg = dracula.very_bright_bg
theme.notif_bg = dracula.bg

-- Menu colors
theme.menu_fg = dracula.fg
theme.menu_bg = dracula.bg
theme.menu_selected_fg = dracula.fg
theme.menu_selected_bg = dracula.bright_bg
theme.menu_title_bg = dracula.bg
theme.menu_primary_title_fg = dracula.red
theme.menu_secondary_title_fg = dracula.bright_bg

theme.menu_disabled_fg = dracula.very_bright_bg
theme.menu_disabled_bg = dracula.purple
theme.menu_enabled_fg = theme.menu_fg
theme.menu_enabled_bg = theme.menu_bg
theme.menu_active_fg = dracula.very_bright_bg
theme.menu_active_bg = theme.menu_bg

-- Proxy manager
theme.proxy_active_menu_fg = dracula.fg
theme.proxy_active_menu_bg = dracula.bg
theme.proxy_inactive_menu_fg = dracula.bright_bg
theme.proxy_inactive_menu_bg = dracula.very_bright_bg

-- Statusbar specific
theme.sbar_fg = dracula.fg
theme.sbar_bg = dracula.bg

-- Downloadbar specific
theme.dbar_fg = dracula.fg
theme.dbar_bg = dracula.bg
theme.dbar_error_fg = dracula.red

-- Input bar specific
theme.ibar_fg = dracula.fg
theme.ibar_bg = dracula.bg

-- Tab label
theme.tab_fg = dracula.fg
theme.tab_bg = dracula.bg
theme.tab_hover_bg = dracula.orange
theme.tab_ntheme = "#ddd"
theme.selected_fg = dracula.fg
theme.selected_bg = dracula.bright_bg
theme.selected_ntheme = "#ddd"
theme.loading_fg = dracula.cyan
theme.loading_bg = dracula.bg

theme.selected_private_tab_bg = dracula.pink
theme.private_tab_bg = dracula.purple

-- Trusted/untrusted ssl colors
theme.trust_fg = dracula.green
theme.notrust_fg = dracula.red

-- Follow mode hints
theme.hint_font = "12px Iosevka Nerd Font, monospace, courier, sans-serif"
theme.hint_fg = dracula.fg
theme.hint_bg = dracula.very_bright_bg
theme.hint_border = "2px dashed " .. dracula.green
theme.hint_opacity = "0.3"
theme.hint_overlay_bg = "rgba(255,255,153,0.3)"
theme.hint_overlay_border = "1px dotted #000"
theme.hint_overlay_selected_bg = "rgba(0,255,0,0.3)"
theme.hint_overlay_selected_border = theme.hint_overlay_border

-- General colour pairings
theme.ok = { fg = dracula.fg, bg = dracula.bg }
theme.warn = { fg = dracula.orange, bg = dracula.bg }
theme.error = { fg = dracula.red, bg = dracula.bright_bg }

-- Gopher page style (override defaults)
theme.gopher_light = { bg = "#E8E8E8", fg = "#17181C", link = "#03678D" }
theme.gopher_dark = { bg = "#17181C", fg = "#E8E8E8", link = "#f90" }

return theme
