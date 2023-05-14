(local noice (require :noice))

(local overrides [:vim.lsp.util.convert_input_to_markdown_lines
                  :vim.lsp.util.stylize_markdown
                  :cmp.entry.get_documentation])

(noice.setup {:message {:view :mini}
              :lsp {:override (collect [_ o (ipairs overrides)] (values o true))}})
