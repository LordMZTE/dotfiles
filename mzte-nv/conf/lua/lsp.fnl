;; Hover-Highlights
(fn on-lsp-attach [args]
  (local buf args.buf)
  (local client (vim.lsp.get_client_by_id args.data.client_id))
  (when (and client.server_capabilities.documentHighlightProvider
             (not vim.b.mzte_reg_hl_aucmd))
    (set vim.b.mzte_reg_hl_aucmd true)
    ;; Symbol highlighting
    (vim.api.nvim_create_autocmd :CursorHold
                                 {:buffer buf
                                  :callback #(pcall vim.lsp.buf.document_highlight)})
    (vim.api.nvim_create_autocmd :CursorMoved
                                 {:buffer buf
                                  :callback #(vim.lsp.buf.clear_references)})))

(vim.api.nvim_create_autocmd :LspAttach {:callback on-lsp-attach})

;; Highlight in bold font
(local hlgroups [:LspReferenceText :LspReferenceRead :LspReferenceWrite])
(each [_ hl (ipairs hlgroups)]
  (vim.api.nvim_set_hl 0 hl {:bold true :bg "#6272a4"}))
