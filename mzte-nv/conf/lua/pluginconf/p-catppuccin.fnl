(print "catppuccin config")
(local (mztenv catppuccin palettes)
       (values (require :mzte_nv) (require :catppuccin)
               (require :catppuccin.palettes)))

(local flavour :mocha)

(catppuccin.setup {: flavour
                   ;; Enable all relevant integrations
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

;; Optimize this by saving the palette table
(let [get-palette palettes.get_palette]
  (set mztenv.reg.catppuccin-palette (get-palette))
  (set palettes.get_palette
       (fn [flav]
         (if (or (not flav) (= flav flavour)) mztenv.reg.catppuccin-palette
             (get-palette flav)))))
