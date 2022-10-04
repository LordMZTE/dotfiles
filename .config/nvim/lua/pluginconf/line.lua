local lline = require "lualine"
local navic = require "nvim-navic"

local function navic_component()
    if navic.is_available() then
        local data = navic.get_data()
        local s = ""

        for i, v in ipairs(data) do
            if v.type ~= "Package" then
                if i ~= 1 then
                    s = s .. "  "
                end

                s = s .. v.icon .. v.name
            end
        end

        return s
    end
    return ""
end

lline.setup {
    options = {
        theme = "dracula",
    },
    sections = {
        lualine_b = { "branch", "diff", "lsp_progress" },
        lualine_c = { "filename", "diagnostics" },
        lualine_x = { "fileformat", "filetype", navic_component },
    },
}
