vim.g.coc_global_extensions = {
    "coc-clangd",
    "coc-fish",
    "coc-go",
    "coc-haxe",
    "coc-java",
    "coc-json",
    "coc-kotlin",
    "coc-lua",
    "coc-rust-analyzer",
    "coc-snippets",
    "coc-tabnine",
    "coc-toml",
}

local function check_back_space()
  local col = vim.fn.col(".") - 1
  return col <= 0 or vim.fn.getline("."):sub(col, col):match("%s")
end

function tab_completion()
  if vim.fn.pumvisible() > 0 then
    return vim.api.nvim_replace_termcodes("<C-n>", true, true, true)
  end

  if check_back_space() then
    return vim.api.nvim_replace_termcodes("<TAB>", true, true, true)
  end

  return vim.fn["coc#refresh"]()
end

vim.api.nvim_set_keymap("i", "<TAB>", "v:lua.tab_completion()", { expr = true, noremap = false })
