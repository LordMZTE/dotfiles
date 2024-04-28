(local (mztenv lline lspprogress)
       (values (require :mzte_nv) (require :lualine) (require :lsp-progress)))

(lline.setup {:options {:theme :catppuccin}
              :sections {:lualine_b [:filename :diff]
                         :lualine_c [:diagnostics]}
              :tabline {:lualine_a [{1 :tabs
                                     ;; show file name
                                     :mode 1}]
                        :lualine_c [#(or (. (lspprogress.progress) :msg) "")]
                        :lualine_y [:branch]}})

(vim.api.nvim_create_autocmd :User
                             {:pattern :LspProgressStatusUpdated
                              :callback lline.refresh})
