(local (mztenv lline lightbulb lspprogress)
       (values (require :mzte_nv) (require :lualine) (require :nvim-lightbulb)
               (require :lsp-progress)))

(lline.setup {:options {:theme :catppuccin}
              :sections {:lualine_b [:filename :diff]
                         :lualine_c [:diagnostics]}
              :tabline {:lualine_a [{1 :tabs
                                     ;; show file name
                                     :mode 1}]
                        :lualine_c [#(or (. (lspprogress.progress) :msg) "")]
                        :lualine_x [:searchcount
                                    {1 #(lightbulb.get_status_text)
                                     :color {:fg mztenv.reg.catppuccin-palette.teal}}]
                        :lualine_y [:branch]}})

(vim.api.nvim_create_autocmd :User
                             {:pattern :LspProgressStatusUpdated
                              :callback lline.refresh})
