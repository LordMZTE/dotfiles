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
  (each [_ r (ipairs [:y :p :P :d])]
    (nmap (.. p r) (.. "\"" p r))))

;; Vimgrep
(nmap :<F4> (cmd :cnext))
(nmap :<S-F4> (cmd :cprevious))

;; LSP
(nmap :-r #(vim.lsp.buf.format {:async true}))
(nmap :<C-k> vim.lsp.buf.signature_help)
(vim.keymap.set :i :<C-k> vim.lsp.buf.signature_help opts)

;; command to stop LSPs
(vim.api.nvim_create_user_command :StopLsps
                                  #(vim.lsp.stop_client (vim.lsp.get_active_clients))
                                  {:nargs 0})
