(local mztenv (require :mzte_nv))
(local cmd vim.cmd)

;; Update $PATH with nvim tools path
(let [lsppath mztenv.reg.nvim_tools]
  (when lsppath
    (set vim.env.PATH (.. lsppath "/bin:" vim.env.PATH))))

;; CPBuf command
(vim.api.nvim_create_user_command :CPBuf mztenv.cpbuf.copyBuf {:nargs 0})

;; Compile commands
(let [compile-path mztenv.compile.compilePath
      make-cmd vim.api.nvim_create_user_command]
  (make-cmd :CompileConfig
            #(compile-path (.. (vim.fn.getenv :HOME) :/.config/nvim)) {:nargs 0}))
