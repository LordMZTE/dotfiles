(vim.cmd "packadd packer.nvim")

(local packer (require :packer))

(macro pconf [plugin]
  `#(require ,(.. :pluginconf.p- plugin)))

(fn use/mztegit [plugin opts]
  (let [url (.. "https://git.mzte.de/nvim-plugins/" plugin)
        opt (or opts {})]
    (tset opt 1 url)
    (packer.use opt)))

(macro use/pconf [plugin conf]
  `(use/mztegit ,plugin {:config (pconf ,conf)}))

(macro use/pconf [plugin conf extra]
  (var c {:config `(pconf ,conf)})
  (each [k v (pairs (or extra {}))]
    (tset c k v))
  `(use/mztegit ,plugin ,c))

(fn cmp-plugins []
  (use/pconf :nvim-lspconfig :lspconf)
  (use/pconf :nvim-cmp :cmp)
  (use/mztegit :cmp-nvim-lsp)
  (use/mztegit :cmp-buffer)
  (use/mztegit :cmp-path)
  (use/mztegit :cmp-cmdline)
  (use/mztegit :cmp_luasnip)
  (use/mztegit :friendly-snippets)
  (use/pconf :LuaSnip :luasnip)
  (use/mztegit :crates.nvim {:config #((. (require :crates) :setup) {})})
  (use/mztegit :cmp-treesitter)
  (use/pconf :null-ls.nvim :nullls)
  (use/mztegit :nvim-nu
               {:config #((. (require :nu) :setup) {:complete_cmd_names true})})
  (use/mztegit :cmp-conjure))

(fn init []
  (use/mztegit :packer.nvim)
  (use/mztegit :plenary.nvim)
  (use/pconf :catppuccin :catppuccin)
  (use/mztegit :gitsigns.nvim {:config #((. (require :gitsigns) :setup) {})})
  (use/mztegit :vim-fish)
  (use/pconf :lualine.nvim :line {:after :catppuccin})
  (use/pconf :nvim-treesitter :treesitter)
  (use/pconf :nvim-web-devicons :devicons)
  (use/pconf :nvim-tree.lua :nvimtree)
  (use/pconf :neogit :neogit)
  (use/pconf :telescope.nvim :telescope)
  (use/pconf :nvim-autopairs :autopairs)
  (use/mztegit :nvim-ts-autotag)
  (use/mztegit :rainbow-delimiters.nvim)
  (use/pconf :toggleterm.nvim :tterm)
  (use/mztegit :wgsl.vim)
  (use/mztegit :nvim-notify)
  ;; TODO: remove once noice gets support for ui.select
  (use/mztegit :dressing.nvim
               {:config #((. (require :dressing) :setup) {:input ;; Provided by noice
                                                          {:enabled false}})})
  (use/pconf :nvim-treesitter-context :ts-context)
  (use/mztegit :crafttweaker-vim-highlighting)
  (use/mztegit :nvim-jdtls)
  (use/mztegit :promise-async)
  (use/pconf :nvim-ufo :ufo {:after :nvim-lspconfig})
  (use/pconf :aerial.nvim :aerial)
  (use/mztegit :nvim-dap-ui)
  (use/pconf :nvim-dap :dap)
  (use/pconf :harpoon :harpoon)
  (use/pconf :nvim-recorder :recorder)
  (use/mztegit :nui.nvim)
  (use/pconf :noice.nvim :noice)
  (use/mztegit :vaxe)
  (use/pconf :ts-node-action :tsn-actions)
  (use/mztegit :playground)
  (use/mztegit :conjure {:setup (pconf :conjure)})
  (use/pconf :nvim-lightbulb :lightbulb)
  (cmp-plugins))

(packer.startup init)

;; PackerCompile automagically
(when (= 0 (length (vim.api.nvim_get_runtime_file :plugin/packer_compiled.lua
                                                  false)))
  (packer.compile))

;; actually compile packer-generated config after packer's "compile" step
(fn compile-packer-generated []
  (let [mztenv (require :mzte_nv)
        packer (require :packer)]
    (mztenv.compile.compilePath packer.config.compile_path)))

(vim.api.nvim_create_autocmd :User
                             {:pattern :PackerCompileDone
                              :once true
                              :callback compile-packer-generated})
