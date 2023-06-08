(local lline (require :lualine))

(lline.setup {:options {:theme :catppuccin}
              :sections {:lualine_b [:filename :diff]
                         :lualine_c [:diagnostics]}
              :tabline {:lualine_a [{1 :tabs
                                     ;; show file name
                                     :mode 1}]
                        :lualine_x [:searchcount]
                        :lualine_y [:branch]}})
