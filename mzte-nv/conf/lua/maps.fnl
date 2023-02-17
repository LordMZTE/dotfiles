(local opts {:noremap true :silent true})

(macro nmap [map action]
  `(vim.api.nvim_set_keymap :n ,map ,action opts))

(macro cmd [c]
  (.. :<cmd> c :<CR>))

(macro lcmd [c]
  `(cmd ,(.. "lua " c)))

;; Getting stuck in ~~vim~~ terminal
(vim.api.nvim_set_keymap :t :<Esc> "<C-\\><C-n>" {})

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
(nmap :-a (lcmd "vim.lsp.buf.code_action()"))
(nmap :-d (lcmd "vim.diagnostic.goto_next()"))
(nmap :-n (lcmd "vim.lsp.buf.rename()"))
(nmap :-r (lcmd "vim.lsp.buf.format { async = true }"))
(nmap :<C-k> (lcmd "vim.lsp.buf.signature_help()"))
(nmap :<space>e (lcmd "vim.diagnostic.open_float()"))
(nmap :K (lcmd "vim.lsp.buf.hover()"))

;; command to stop LSPs
(vim.api.nvim_create_user_command :StopLsps
                                  #(vim.lsp.stop_client (vim.lsp.get_active_clients))
                                  {:nargs 0})
