(local (mztenv lline lightbulb)
       (values (require :mzte_nv) (require :lualine) (require :nvim-lightbulb)))

(lline.setup {:options {:theme :catppuccin}
              :sections {:lualine_b [:filename :diff]
                         :lualine_c [:diagnostics]}
              :tabline {:lualine_a [{1 :tabs
                                     ;; show file name
                                     :mode 1}]
                        :lualine_x [:searchcount
                                    {1 #(lightbulb.get_status_text)
                                     :color {:fg mztenv.reg.catppuccin-palette.teal}}]
                        :lualine_y [:branch]}})
