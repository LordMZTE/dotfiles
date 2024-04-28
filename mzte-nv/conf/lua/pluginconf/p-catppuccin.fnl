(local (mztenv catppuccin palettes)
       (values (require :mzte_nv) (require :catppuccin)
               (require :catppuccin.palettes)))

(local flavour :mocha)

(catppuccin.setup {: flavour
                   :term_colors true
                   :dim_inactive {:enabled true}
                   ;; Enable all relevant integrations
                   :default_integrations false
                   :integrations {:cmp true
                                  :dap true
                                  :dap_ui true
                                  :gitsigns true
                                  :harpoon true
                                  :lsp_saga true
                                  :markdown true
                                  :native_lsp {:enabled true
                                               :virtual_text (collect [_ diag (ipairs [:errors
                                                                                       :hints
                                                                                       :warnings
                                                                                       :information])]
                                                               (values diag
                                                                       [:italic]))
                                               :underlines (collect [_ diag (ipairs [:errors
                                                                                     :hints
                                                                                     :warnings
                                                                                     :information])]
                                                             (values diag
                                                                     [:underline]))
                                               :inlay_hints {:background true}}
                                  :neogit true
                                  :nvimtree true
                                  :rainbow_delimiters true
                                  :semantic_tokens true
                                  :telescope {:enabled true}
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
