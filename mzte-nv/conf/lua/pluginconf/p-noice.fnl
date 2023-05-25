(local noice (require :noice))

(local overrides [:vim.lsp.util.convert_input_to_markdown_lines
                  :vim.lsp.util.stylize_markdown
                  :cmp.entry.get_documentation])

(noice.setup {:messages {:view :mini}
              :lsp {:override (collect [_ o (ipairs overrides)] (values o true))}
              :presets {:lsp_doc_border true}})

;; Shift-Enter to redirect cmdline
(vim.keymap.set :c :<S-Enter> #(noice.redirect (vim.fn.getcmdline))
                {:desc "Redirect Cmdline"})
