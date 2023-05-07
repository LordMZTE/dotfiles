(local autopairs (require :nvim-autopairs))
(local cmp-autopairs (require :nvim-autopairs.completion.cmp))
(local cmp (require :cmp))

(autopairs.setup {:check_ts true
                  :fast_wrap {}
                  :enable_check_bracket_line false})

(cmp.event:on :confirm_done
              (cmp-autopairs.on_confirm_done {:map_char {:tex ""}}))
