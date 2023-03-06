(local aerial (require :aerial))

(aerial.setup {:backends [:lsp :treesitter :markdown :man]})

(vim.keymap.set :n :-o #(aerial.toggle) {:noremap true :silent true})
