(local opts (. (require :mzte_nv) :utils :map_opt))

(macro nmap [map action]
  `(vim.keymap.set :n ,map ,action opts))

(macro cmd [c]
  (.. :<cmd> c :<CR>))

;; Getting stuck in ~~vim~~ terminal
(vim.keymap.set :t :<Esc> "<C-\\><C-n>" opts)

;; Quick cursor movement
(nmap :<C-Down> :5j)
(nmap :<C-Up> :5k)

;; Quick system register access
(each [_ p (ipairs ["+" "*"])]
  (each [_ r (ipairs [:y :p :d])]
    (nmap (.. p r) (.. "\"" p r))))

;; Vimgrep
(nmap :<F4> (cmd :cnext))
(nmap :<S-F4> (cmd :cprevious))

;; LSP
(nmap :-a vim.lsp.buf.code_action)
(nmap :-d vim.diagnostic.goto_next)
(nmap :-n vim.lsp.buf.rename)
(nmap :-r #(vim.lsp.buf.format {:async true}))
(nmap :<C-k> vim.lsp.buf.signature_help)
(nmap :<space>e vim.diagnostic.open_float)

(nmap :K vim.lsp.buf.hover)

;; command to stop LSPs
(vim.api.nvim_create_user_command :StopLsps
                                  #(vim.lsp.stop_client (vim.lsp.get_active_clients))
                                  {:nargs 0})
