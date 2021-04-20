local map = vim.api.nvim_set_keymap

-- Getting stuck in ~~vim~~ terminal
map("t", "<Esc>", "<C-\\><C-n>", { noremap = true })
map("n", "fzf", ":FZF<CR>", { silent = true, noremap = true })

-- Quick cursor movement
map("n", "<C-Down>", "5k", { noremap = true })
map("n", "<C-Up>", "5j", { noremap = true })

-- Quick pasting/yoinking to system register
map("n", "+y", "\"+y", { noremap = true })
map("n", "+p", "\"+p", { noremap = true })
map("n", "+d", "\"+d", { noremap = true })

map("n", "*y", "\"*y", { noremap = true })
map("n", "*p", "\"*p", { noremap = true })
map("n", "*d", "\"*d", { noremap = true })

-- symbol renaming
map("n", "cn", "<Plug>(coc-rename)", { silent = true, noremap = true })
-- apply AutoFix to problem on current line
map("n", "cf", "<Plug>(coc-fix-current)", { silent = true, noremap = true })
-- open action dialog
map("n", "ca", ":CocAction<CR>", { silent = true, noremap = true })

-- GoTo code navigation.
map("n", "gd", "<Plug>(coc-definition)", { silent = true, noremap = true })
map("n", "gy", "<Plug>(coc-type-definition)", { silent = true, noremap = true })
map("n", "gi", "<Plug>(coc-implementation)", { silent = true, noremap = true })
map("n", "gr", "<Plug>(coc-references)", { silent = true, noremap = true })

-- Use K to show documentation in preview window.
map("n", "K", ":call CocActionAsync(\'doHover\')<CR>", { silent = true, noremap = true })

-- use space o to show symbols
map("n", "<space>o", ":CocList -I symbols<CR>", { silent = true, noremap = true })

-- format code
map("n", "cr", ":call CocActionAsync(\'format\')<CR>", { silent = true, noremap = true })

