coc = {}

vim.g.coc_global_extensions = {
    "coc-clangd",
    "coc-fish",
    "coc-go",
    "coc-haxe",
    "coc-java",
    "coc-json",
    "coc-kotlin",
    "coc-rust-analyzer",
    "coc-snippets",
    "coc-sumneko-lua",
    "coc-toml",
}

local function check_back_space()
    local col = vim.fn.col "." - 1
    return col <= 0 or vim.fn.getline("."):sub(col, col):match "%s"
end

function coc.tab_completion()
    if vim.fn.pumvisible() > 0 then
        return escape_keycode "<C-n>"
    end

    if check_back_space() then
        return escape_keycode "<TAB>"
    end

    return vim.fn["coc#refresh"]()
end

function coc.shift_tab_completion()
    if vim.fn.pumvisible() > 0 then
        return escape_keycode "<C-p>"
    else
        return escape_keycode "<C-h>"
    end
end

function coc.cr_completion()
    if vim.fn.pumvisible() > 0 then
        return vim.fn["coc#_select_confirm"]()
    else
        return escape_keycode [[\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>]]
    end
end
