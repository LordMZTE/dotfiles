;; This is needed by our fancy right-aligned inlay hints so we can recalculate their size to never
;; block actual code when we resize.
(fn refresh-inlay-hints [bufnr]
  (let [filter {: bufnr}]
    (when vim.lsp.inlay_hint.is_enabled filter
      (vim.lsp.inlay_hint.enable true filter))))

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
                                  :callback #(vim.lsp.buf.clear_references)}))
  (when client.server_capabilities.inlayHintProvider
    (vim.lsp.inlay_hint.enable true {:bufnr buf})
    (vim.api.nvim_create_autocmd [:VimResized :WinResized]
                                 {:buffer buf
                                  :desc "Refresh inlay hints"
                                  :callback #(refresh-inlay-hints $1.buf)})))

(vim.api.nvim_create_autocmd :LspAttach {:callback on-lsp-attach})

;; Highlight in bold font
(local hlgroups [:LspReferenceText :LspReferenceRead :LspReferenceWrite])
(each [_ hl (ipairs hlgroups)]
  (vim.api.nvim_set_hl 0 hl {:bold true :bg "#6272a4"}))
