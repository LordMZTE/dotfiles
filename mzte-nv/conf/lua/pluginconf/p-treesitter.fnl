(local nvim-treesitter (require :nvim-treesitter))

(local install-dir (.. (vim.loop.os_homedir) :/.local/share/nvim/ts-parsers))
(vim.opt.runtimepath:append install-dir)

(nvim-treesitter.setup {:install_dir install-dir})

(fn enable []
  (let [lang (vim.treesitter.language.get_lang vim.bo.filetype)
        (have-parser _) (pcall vim.treesitter.language.inspect lang)]
    (when have-parser
      (vim.treesitter.start)
      (set vim.bo.indentexpr "v:lua.require'nvim-treesitter'.indentexpr()"))))

(vim.api.nvim_create_autocmd :FileType {:callback enable})
