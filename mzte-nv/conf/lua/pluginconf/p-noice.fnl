(local (mztenv noice) (values (require :mzte_nv) (require :noice)))

(local overrides [:vim.lsp.util.convert_input_to_markdown_lines
                  :vim.lsp.util.stylize_markdown
                  :cmp.entry.get_documentation])

(fn show-mini? [notif]
  (or ;; INFO level
      (= notif.level :info) (and notif.opts notif.opts.mzte_nv_mini)))

(noice.setup {:messages {:view :mini}
              :lsp {:override (collect [_ o (ipairs overrides)] (values o true))}
              :routes [;; Redirect DAP messages to mini view
                       {:filter {:event :notify :cond show-mini?} :view :mini}]
              :presets {:lsp_doc_border true}})

;; Shift-Enter to redirect cmdline
(vim.keymap.set :c :<S-Enter> #(noice.redirect (vim.fn.getcmdline))
                {:desc "Redirect Cmdline"})

;; These default to info diagnostic colors (WTF)
(each [_ hl (pairs [:NoiceCmdlinePopupBorder
                    :NoiceCmdlineIcon
                    :NoiceCmdlinePopupTitle])]
  (vim.api.nvim_set_hl 0 hl {:link :DraculaCyan}))
