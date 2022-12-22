local map = vim.api.nvim_set_keymap

require("harpoon").setup {}

map("n", "ma", [[<cmd>lua require("harpoon.mark").toggle_file()<cr>]], { silent = true })
map("n", "mn", [[<cmd>lua require("harpoon.ui").nav_next()<cr>]], { silent = true })
map("n", "mp", [[<cmd>lua require("harpoon.ui").nav_prev()<cr>]], { silent = true })
