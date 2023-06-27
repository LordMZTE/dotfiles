(local lightbulb (require :nvim-lightbulb))

(local ignored-clients [:null-ls])

(lightbulb.setup {:ignore ignored-clients
                  ;; No gutter sign
                  :sign {:enabled false}
                  ;; Status bar text
                  :status_text {:enabled true :text "󱐌"}})

;; Create update autocmd on LSP attach
(fn on-lsp-attach [args]
  (let [buf args.buf
        client (vim.lsp.get_client_by_id args.data.client_id)]
    (when (and client.server_capabilities.codeActionProvider
               (not vim.b.mzte_reg_lighbulb_aucmd)
               (not (vim.list_contains ignored-clients client.name)))
      (set vim.b.mzte_reg_lighbulb_aucmd true)
      (vim.api.nvim_create_autocmd :CursorHold
                                   {:buffer buf
                                    :callback lightbulb.update_lightbulb}))))

(vim.api.nvim_create_autocmd :LspAttach {:callback on-lsp-attach})
