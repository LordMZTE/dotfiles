map = vim.api.nvim_set_keymap

function escape_keycode(keycode)
	return vim.api.nvim_replace_termcodes(keycode, true, true, true)
end

local function check_back_space()
	local col = vim.fn.col(".") - 1
	return col <= 0 or vim.fn.getline("."):sub(col, col):match("%s")
end

function tab_completion()
	if vim.fn.pumvisible() > 0 then
		return escape_keycode("<C-n>")
	end

	if check_back_space() then
		return escape_keycode("<TAB>")
	end

	return vim.fn["coc#refresh"]()
end

function shift_tab_completion()
	if vim.fn.pumvisible() > 0 then
		return escape_keycode("<C-p>")
	else
		return escape_keycode("<C-h>")
	end
end

-- Getting stuck in ~~vim~~ terminal
map("t", "<Esc>", "<C-\\><C-n>", {})

-- telescope
map("n", "ff", "<cmd>Telescope find_files<cr>", { silent = true })
map("n", "fg", "<cmd>Telescope live_grep<cr>", { silent = true })

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

map("i", "<TAB>", "v:lua.tab_completion()", { expr = true })
map("i", "<S-TAB>", "v:lua.shift_tab_completion()", { expr = true })

-- symbol renaming
map("n", "-n", "<Plug>(coc-rename)", { silent = true })
-- apply AutoFix to problem on current line
map("n", "-f", "<Plug>(coc-fix-current)", { silent = true })
-- open action dialog
map("n", "-a", ":CocAction<CR>", { silent = true })

-- GoTo code navigation.
map("n", "gd", "<Plug>(coc-definition)", { silent = true })
map("n", "gy", "<Plug>(coc-type-definition)", { silent = true })
map("n", "gi", "<Plug>(coc-implementation)", { silent = true })
map("n", "gr", "<Plug>(coc-references)", { silent = true })

-- Use K to show documentation in preview window.
map("n", "K", ":call CocActionAsync('doHover')<CR>", { silent = true })

-- use space o to show symbols
map("n", "<space>o", ":CocList -I symbols<CR>", { silent = true })

-- format code
map("n", "-r", ":call CocActionAsync('format')<CR>", { silent = true })

-- Use <c-space> to trigger completion.
map("i", "<c-space>", "coc#refresh()", { silent = true, expr = true })

-- Use -d to jump to next diagnostic
map("n", "-d", "<Plug>(coc-diagnostic-next)", { silent = true })

-- Use -o to show outline
map("n", "-o", ":CocList outline<CR>", { silent = true })
