(vim.cmd "packadd packer.nvim")

(local packer (require :packer))

(macro pconf [plugin]
  `#(require ,(.. :pluginconf.p- plugin)))

(macro use/pconf [use plugin conf]
  `(,use {1 ,plugin :config (pconf ,conf)}))

(macro use/pconf [use plugin conf extra]
  (var c {1 plugin :config `(pconf ,conf)})
  (when (table? extra)
    (each [k v (pairs extra)]
      (tset c k v)))
  `(,use ,c))

(fn cmp-plugins [use]
  (use/pconf use :neovim/nvim-lspconfig :lspconf)
  (use/pconf use :hrsh7th/nvim-cmp :cmp)
  (use :hrsh7th/cmp-nvim-lsp)
  (use :hrsh7th/cmp-buffer)
  (use :hrsh7th/cmp-path)
  (use :hrsh7th/cmp-cmdline)
  (use :saadparwaiz1/cmp_luasnip)
  (use/pconf use :L3MON4D3/LuaSnip :luasnip
             {:requires :rafamadriz/friendly-snippets})
  (use {1 :Saecki/crates.nvim :config #((. (require :crates) :setup) {})})
  (use :ray-x/cmp-treesitter)
  (use/pconf use :jose-elias-alvarez/null-ls.nvim :nullls)
  (use {1 :LhKipp/nvim-nu
        :config #((. (require :nu) :setup) {:complete_cmd_names true})})
  (use :PaterJason/cmp-conjure))

(fn init [use]
  (use :wbthomason/packer.nvim)
  (use/pconf use :catppuccin/nvim :catppuccin {:as :catppuccin})
  (use {1 :lewis6991/gitsigns.nvim
        :config #((. (require :gitsigns) :setup) {})})
  (use :dag/vim-fish)
  (use/pconf use :nvim-lualine/lualine.nvim :line
             {:after :catppuccin})
  (use/pconf use :nvim-treesitter/nvim-treesitter :treesitter)
  (use/pconf use :nvim-tree/nvim-web-devicons :devicons)
  (use/pconf use :nvim-tree/nvim-tree.lua :nvimtree
             {:requires :nvim-tree/nvim-web-devicons})
  (use/pconf use :TimUntersberger/neogit :neogit
             {:requires :nvim-lua/plenary.nvim})
  (use/pconf use :nvim-telescope/telescope.nvim :telescope
             {:requires :nvim-lua/plenary.nvim})
  (use/pconf use :windwp/nvim-autopairs :autopairs)
  (use :windwp/nvim-ts-autotag)
  (use :HiPhish/nvim-ts-rainbow2)
  (use/pconf use :akinsho/toggleterm.nvim :tterm)
  (use :DingDean/wgsl.vim)
  (use :rcarriga/nvim-notify)
  ;; TODO: remove once noice gets support for ui.select
  (use {1 :stevearc/dressing.nvim
        :config #((. (require :dressing) :setup) {:input ;; Provided by noice
                                                  {:enabled false}})})
  (use/pconf use :nvim-treesitter/nvim-treesitter-context :ts-context)
  (use :DaeZak/crafttweaker-vim-highlighting)
  (use :mfussenegger/nvim-jdtls)
  (use/pconf use :kevinhwang91/nvim-ufo :ufo
             {:requires :kevinhwang91/promise-async :after :nvim-lspconfig})
  (use/pconf use :stevearc/aerial.nvim :aerial)
  (use/pconf use :mfussenegger/nvim-dap :dap {:requires :rcarriga/nvim-dap-ui})
  (use/pconf use :ThePrimeagen/harpoon :harpoon)
  (use/pconf use :chrisgrieser/nvim-recorder :recorder)
  (use/pconf use :folke/noice.nvim :noice {:requires :MunifTanjim/nui.nvim})
  (use :jdonaldson/vaxe)
  (use/pconf use :CKolkey/ts-node-action :tsn-actions
             {:requires :jose-elias-alvarez/null-ls.nvim})
  (use :nvim-treesitter/playground)
  (use {1 :Olical/conjure :setup (pconf :conjure)})
  (use/pconf use :kosayoda/nvim-lightbulb :lightbulb)
  (cmp-plugins use))

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
