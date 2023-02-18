(local cmd vim.cmd)

(local (wo g opt) (values vim.wo vim.g vim.opt))

(cmd "syntax on")

;; Indentation
(set opt.tabstop 4)
(set opt.shiftwidth 4)
(set opt.expandtab true)

;; Search
(set opt.ignorecase true)
(set opt.smartcase true)

;; Window config
(set opt.scrolloff 10)
(set opt.number true)
(set opt.relativenumber true)
(set opt.guifont "Iosevka Nerd Font Mono:h10")
(set opt.mouse :a)
(set opt.termguicolors true)
(set opt.cursorline true)
(set opt.cursorcolumn true)

;; Folds
(set opt.conceallevel 2)

;; Disable unwanted filetype mappings
(set g.no_plugin_maps true)

;; Other settings
(cmd "colorscheme dracula")
(cmd "filetype plugin on")

;; Disable garbage providers
(let [garbage [:python :python3 :ruby :perl :node]]
  (each [_ ga (ipairs garbage)]
    (tset g (.. :loaded_ ga :_provider) false)))

;; Compile commands
(let [compile-path (. (require :mzte_nv) :compile :compilePath)
      make-cmd vim.api.nvim_create_user_command]
  (make-cmd :CompileConfig
            #(compile-path (.. (vim.fn.getenv :HOME) :/.config/nvim)) {:nargs 0})
  (make-cmd :CompilePlugins
            #(compile-path (. (require :packer) :config :package_root))
            {:nargs 0}))
