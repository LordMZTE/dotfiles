(local catppuccin (require :catppuccin))

(catppuccin.setup {;; Enable all relevant integrations
                   :integrations {:aerial true
                                  :harpoon true
                                  :gitsigns true
                                  :neogit true
                                  :noice true
                                  :cmp true
                                  :dap {:enabled true :enable_ui true}
                                  :native_lsp {:enabled true}
                                  :notify true
                                  :nvimtree true
                                  :treesitter true
                                  :treesitter_context true
                                  :ts_rainbow2 true
                                  :telescope true}})

(vim.cmd.colorscheme :catppuccin)
