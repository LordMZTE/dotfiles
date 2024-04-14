(local mztenv (require :mzte_nv))

(let [path mztenv.reg.nvim_plugins]
  (when path
    (vim.opt.runtimepath:append (.. path "/*"))))

(let [plugins [:lspconf
               :cmp
               :luasnip
               :nullls
               :catppuccin
               :line
               :treesitter
               :devicons
               :nvimtree
               :neogit
               :telescope
               :autopairs
               :tterm
               :ts-context
               :ufo
               :aerial
               :dap
               :harpoon
               :recorder
               :noice
               :tsn-actions
               :lightbulb
               :dressing]
      errors {}]
  (each [_ p (ipairs plugins)]
    (let [(success ret) (pcall require (.. :pluginconf/p- p))]
      (when (not success)
        (tset errors p ret))))
  (when (next errors)
    (vim.notify (accumulate [text "Errors loading plugin configs:\n" plugin err (pairs errors)]
                  (.. text "  - " plugin ": " err))
                vim.log.levels.error)))
