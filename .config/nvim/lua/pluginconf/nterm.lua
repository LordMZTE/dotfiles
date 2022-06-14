local nterm = require "neoterm"

nterm.setup {
    clear_on_run = true,
    mode = "vertical",
    noinsert = true,
}

vim.api.nvim_create_autocmd("User", {
  pattern = "NeotermTermLeave",
  callback = nterm.close,
})
