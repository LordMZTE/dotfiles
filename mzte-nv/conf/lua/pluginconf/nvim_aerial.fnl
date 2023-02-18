(local aerial (require :aerial))

(aerial.setup {:backends [:lsp :treesitter :markdown :man]})

(vim.api.nvim_set_keymap :n :-o :<cmd>AerialToggle<CR>
                         {:noremap true :silent true})
