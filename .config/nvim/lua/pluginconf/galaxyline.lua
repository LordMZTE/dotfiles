-- BASED OFF https://github.com/LoydAndrew/nvim/blob/main/evilline.lua

local gl = require "galaxyline"
local gls = gl.section

gl.short_line_list = {
    "LuaTree",
    "vista",
    "dbui",
    "startify",
    "term",
    "nerdtree",
    "fugitive",
    "fugitiveblame",
    "plug",
}

-- VistaPlugin = extension.vista_nearest

local colors = {
    bg = "#44475a",
    line_bg = "#282c34",
    fg = "#f8f8f2",
    fg_green = "#65a380",
    yellow = "#f1fa8c",
    cyan = "#8be9fd",
    darkblue = "#081633",
    green = "#50fa7b",
    orange = "#ffb86c",
    purple = "#bd93f9",
    magenta = "#ff79c6",
    blue = "#51afef",
    red = "#ff5555",
}

local mode_color = {
    n = colors.green,
    i = colors.blue,
    v = colors.magenta,
    [""] = colors.blue,
    V = colors.blue,
    no = colors.magenta,
    s = colors.orange,
    S = colors.orange,
    [""] = colors.orange,
    ic = colors.yellow,
    cv = colors.red,
    ce = colors.red,
    ["!"] = colors.green,
    t = colors.green,
    c = colors.purple,
    ["r?"] = colors.red,
    ["r"] = colors.red,
    rm = colors.red,
    R = colors.yellow,
    Rv = colors.magenta,
}

local function trailing_whitespace()
    local trail = vim.fn.search("\\s$", "nw")
    if trail ~= 0 then
        return " "
    else
        return nil
    end
end

TrailingWhiteSpace = trailing_whitespace

local function has_file_type()
    local f_type = vim.bo.filetype
    if not f_type or f_type == "" then
        return false
    end
    return true
end

local buffer_not_empty = function()
    if vim.fn.empty(vim.fn.expand "%:t") ~= 1 then
        return true
    end
    return false
end

gls.left[1] = {
    FirstElement = {
        provider = function()
            return " "
        end,
        highlight = { colors.blue, colors.line_bg },
    },
}
gls.left[2] = {
    ViMode = {
        provider = function()
            -- auto change color according the vim mode
            local alias = {
                n = "NORMAL",
                i = "INSERT",
                V = "VISUAL",
                [""] = "VISUAL",
                v = "VISUAL",
                c = "COMMAND-LINE",
                ["r?"] = ":CONFIRM",
                rm = "--MORE",
                R = "REPLACE",
                Rv = "VIRTUAL",
                s = "SELECT",
                S = "SELECT",
                ["r"] = "HIT-ENTER",
                [""] = "SELECT",
                t = "TERMINAL",
                ["!"] = "SHELL",
            }
            local vim_mode = vim.fn.mode()
            vim.api.nvim_command("hi GalaxyViMode guibg=" .. mode_color[vim_mode])
            return alias[vim_mode] .. "   "
        end,
        highlight = { colors.line_bg, colors.line_bg, "bold" },
    },
}
gls.left[3] = {
    ModeSep = {
        provider = function()
            vim.api.nvim_command("hi GalaxyModeSep guifg=" .. mode_color[vim.fn.mode()] .. " guibg=" .. colors.bg)
            return ""
        end,
        highlight = { colors.line_bg, colors.line_bg },
        separator = " ",
        separator_highlight = { colors.bg, colors.line_bg },
    },
}
gls.left[4] = {
    FileIcon = {
        provider = "FileIcon",
        condition = buffer_not_empty,
        highlight = { require("galaxyline.provider_fileinfo").get_file_icon_color, colors.line_bg },
    },
}
gls.left[5] = {
    FileName = {
        provider = { "FileName", "FileSize" },
        condition = buffer_not_empty,
        highlight = { colors.fg, colors.line_bg, "bold" },
    },
}

gls.left[6] = {
    GitIcon = {
        provider = function()
            return "  "
        end,
        condition = require("galaxyline.provider_vcs").check_git_workspace,
        highlight = { colors.orange, colors.line_bg },
    },
}
gls.left[7] = {
    GitBranch = {
        provider = "GitBranch",
        condition = require("galaxyline.provider_vcs").check_git_workspace,
        highlight = { "#8FBCBB", colors.line_bg, "bold" },
    },
}

local checkwidth = function()
    local squeeze_width = vim.fn.winwidth(0) / 2
    if squeeze_width > 40 then
        return true
    end
    return false
end

gls.left[8] = {
    DiffAdd = {
        provider = "DiffAdd",
        condition = checkwidth,
        icon = " ",
        highlight = { colors.green, colors.line_bg },
    },
}
gls.left[9] = {
    DiffModified = {
        provider = "DiffModified",
        condition = checkwidth,
        icon = " ",
        highlight = { colors.orange, colors.line_bg },
    },
}
gls.left[10] = {
    DiffRemove = {
        provider = "DiffRemove",
        condition = checkwidth,
        icon = " ",
        highlight = { colors.red, colors.line_bg },
    },
}
gls.left[11] = {
    TrailingWhiteSpace = {
        provider = TrailingWhiteSpace,
        icon = "  ",
        highlight = { colors.yellow, colors.line_bg },
    },
}
gls.left[12] = {
    ShowLspClient = {
        provider = "GetLspClient",
        icon = "   ",
        highlight = { colors.green, colors.line_bg },
    }
}
gls.left[13] = {
    SpaceBefore = {
        provider = function()
            return " "
        end,
        highlight = { colors.line_bg, colors.line_bg },
    },
}
gls.left[14] = {
    LeftEnd = {
        provider = function()
            return ""
        end,
        highlight = { colors.line_bg, colors.bg },
    },
}
gls.left[15] = {
    SpaceAfter = {
        provider = function()
            return " "
        end,
        highlight = { colors.bg, colors.bg },
    },
}

gls.left[16] = {
    DiagnosticError = {
        provider = "DiagnosticError",
        icon = "  ",
        highlight = { colors.red, colors.bg },
    },
}
gls.left[17] = {
    DiagnosticWarn = {
        provider = "DiagnosticWarn",
        icon = "  ",
        highlight = { colors.yellow, colors.bg },
    },
}

gls.right[1] = {
    BufferType = {
        provider = "FileTypeName",
        separator = "",
        condition = has_file_type,
        separator_highlight = { colors.line_bg, colors.bg },
        highlight = { colors.fg, colors.line_bg },
    },
}

gls.right[2] = {
    TypeSep = {
        provider = function()
            return ""
        end,
        highlight = { colors.bg, colors.line_bg },
    },
}

gls.right[3] = {
    FileFormat = {
        provider = "FileFormat",
        separator = "",
        separator_highlight = { colors.line_bg, colors.bg },
        highlight = { colors.fg, colors.line_bg, "bold" },
    },
}

gls.right[4] = {
    LineInfo = {
        provider = "LineColumn",
        separator = " |",
        separator_highlight = { colors.blue, colors.line_bg },
        highlight = { colors.fg, colors.line_bg },
    },
}
gls.right[5] = {
    PerCent = {
        provider = "LinePercent",
        highlight = { colors.cyan, colors.darkblue, "bold" },
    },
}

gls.right[6] = {
    ScrollBar = {
        provider = "ScrollBar",
        highlight = { colors.blue, colors.purple },
    },
}

gls.short_line_left[1] = {
    BufferType = {
        provider = "FileTypeName",
        separator = "",
        condition = has_file_type,
        separator_highlight = { colors.purple, colors.bg },
        highlight = { colors.fg, colors.purple },
    },
}

gls.short_line_right[1] = {
    BufferIcon = {
        provider = "BufferIcon",
        separator = "",
        condition = has_file_type,
        separator_highlight = { colors.purple, colors.bg },
        highlight = { colors.fg, colors.purple },
    },
}
