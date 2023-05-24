(local cmd vim.cmd)

;; Compile commands
(let [compile-path (. (require :mzte_nv) :compile :compilePath)
      make-cmd vim.api.nvim_create_user_command]
  (make-cmd :CompileConfig
            #(compile-path (.. (vim.fn.getenv :HOME) :/.config/nvim)) {:nargs 0})
  (make-cmd :CompilePlugins
            #(compile-path (. (require :packer) :config :package_root))
            {:nargs 0}))
