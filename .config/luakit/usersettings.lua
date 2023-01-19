local settings = require "settings"

local font_family = "Iosevka Nerd Font"

settings.application.prefer_dark_mode = true

settings.webview.enable_accelerated_2d_canvas = true
settings.webview.enable_webgl = true
settings.webview.javascript_can_access_clipboard = true

settings.webview.default_font_family = font_family
settings.webview.monospace_font_family = font_family
settings.webview.sans_serif_font_family = font_family
settings.webview.serif_font_family = font_family

settings.window.default_search_engine = "duckduckgo"
settings.window.home_page = "luakit://newtab"

require("editor").editor_cmd = "neovide --nofork {file}"
