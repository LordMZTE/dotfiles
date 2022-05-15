local map = vim.api.nvim_set_keymap

-- Getting stuck in ~~vim~~ terminal
map("t", "<Esc>", "<C-\\><C-n>", {})

-- telescope
map("n", "ff", "<cmd>Telescope find_files<cr>", { silent = true })
map("n", "fg", "<cmd>Telescope live_grep<cr>", { silent = true })

-- neoterm.nvim
map("n", "tt", "<cmd>NeotermToggle<cr>", { silent = true })
map("n", "tr", ":NeotermRun<space>", {})
map("n", "te", "<cmd>NeotermExit<cr>", { silent = true })
map("n", "ta", "<cmd>NeotermRerun<cr>", { silent = true })

-- Quick cursor movement
map("n", "<C-Down>", "5j", { noremap = true })
map("n", "<C-Up>", "5k", { noremap = true })

-- Quick pasting/yoinking to system register
map("n", "+y", '"+y', { noremap = true })
map("n", "+p", '"+p', { noremap = true })
map("n", "+d", '"+d', { noremap = true })

map("n", "*y", '"*y', { noremap = true })
map("n", "*p", '"*p', { noremap = true })
map("n", "*d", '"*d', { noremap = true })
