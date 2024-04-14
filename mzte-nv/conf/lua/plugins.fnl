(local mztenv (require :mzte_nv))

(tset mztenv.reg :plugin_load_callbacks [])

(let [path mztenv.reg.nvim_plugins]
  (when path
    (vim.opt.runtimepath:prepend (.. path "/*"))
    (vim.opt.runtimepath:append (.. path "/*/after"))))

;; Plugins to load before nvim finishes startup
(local startup-plugins [])

;; Plugins to load in the background
(local deferred-plugins [:lspconf
                         :cmp
                         :luasnip
                         :nullls
                         :catppuccin
                         :line
                         :treesitter
                         :nvimtree
                         :devicons
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
                         :dressing])

(local errors {})

(fn load-plugin [plugin]
  (let [(success ret) (pcall require (.. :pluginconf/p- plugin))]
    (when (not success)
      (tset errors p ret))))

(each [_ p (ipairs startup-plugins)]
  (load-plugin p))

(fn load-one-deferred [idx]
  (let [plugin (. deferred-plugins idx)]
    (if plugin
        (do
          (load-plugin plugin)
          (vim.schedule #(load-one-deferred (+ idx 1))))
        (do
          (when (next errors)
            (vim.notify (accumulate [text "Errors loading plugin configs:\n" plugin err (pairs errors)]
                          (.. text "  - " plugin ": " err))
                        vim.log.levels.error))
          (each [_ cb (ipairs mztenv.reg.plugin_load_callbacks)]
            (pcall cb))))))

(vim.schedule #(load-one-deferred 1))
