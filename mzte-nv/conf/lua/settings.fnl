(local mztenv (require :mzte_nv))
(local cmd vim.cmd)

;; CPBuf command
(vim.api.nvim_create_user_command :CPBuf mztenv.cpbuf.copyBuf {:nargs 0})

;; Compile commands
(let [compile-path mztenv.compile.compilePath
      make-cmd vim.api.nvim_create_user_command]
  (make-cmd :CompileConfig
            #(compile-path (.. (vim.fn.getenv :HOME) :/.config/nvim)) {:nargs 0})
  (make-cmd :CompilePlugins
            #(compile-path (. (require :packer) :config :package_root))
            {:nargs 0}))
