(local (mztenv catppuccin palettes)
       (values (require :mzte_nv) (require :catppuccin)
               (require :catppuccin.palettes)))

(local flavour :mocha)

(catppuccin.setup {: flavour
                   ;; Enable all relevant integrations
                   :integrations {:aerial true
                                  :cmp true
                                  :dap {:enabled true :enable_ui true}
                                  :gitsigns true
                                  :harpoon true
                                  :native_lsp {:enabled true}
                                  :neogit true
                                  :noice true
                                  :notify true
                                  :nvimtree true
                                  :rainbow_delimiters true
                                  :telescope true
                                  :treesitter true
                                  :treesitter_context true}})

(vim.cmd.colorscheme :catppuccin)

;; Optimize this by saving the palette table
(let [get-palette palettes.get_palette]
  (set mztenv.reg.catppuccin-palette (get-palette))
  (set palettes.get_palette
       (fn [flav]
         (if (or (not flav) (= flav flavour)) mztenv.reg.catppuccin-palette
             (get-palette flav)))))
