local map = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }

-- Getting stuck in ~~vim~~ terminal
map("t", "<Esc>", "<C-\\><C-n>", {})

-- Quick cursor movement
map("n", "<C-Down>", "5j", opts)
map("n", "<C-Up>", "5k", opts)

-- Quick pasting/yoinking to system register
map("n", "+y", '"+y', opts)
map("n", "+p", '"+p', opts)
map("n", "+d", '"+d', opts)

map("n", "*y", '"*y', opts)
map("n", "*p", '"*p', opts)
map("n", "*d", '"*d', opts)

-- Vimgrep
map("n", "<F4>", "<cmd>:cnext<CR>", opts)
map("n", "<S-F4>", "<cmd>:cprevious<CR>", opts)

-- See `:help vim.lsp.*` for documentation on any of the below functions
map("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", opts)
map("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", opts)
map("n", "<C-k>", "<cmd>lua vim.lsp.buf.signature_help()<CR>", opts)
map("n", "-n", "<cmd>lua vim.lsp.buf.rename()<CR>", opts)
map("n", "-a", "<cmd>lua vim.lsp.buf.code_action()<CR>", opts)
map("n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>", opts)
map("n", "<space>e", "<cmd>lua vim.diagnostic.open_float()<CR>", opts)
map("n", "-d", "<cmd>lua vim.diagnostic.goto_next()<CR>", opts)
map("n", "-r", "<cmd>lua vim.lsp.buf.format { asnyc = true }<CR>", opts)
