(local lspc (require :lspconfig))
(local lsp-configs (require :lspconfig.configs))

(macro setup [conf args]
  (var args args)
  (when (not args)
    (set args {}))
  (when (not (. args :on_attach))
    (tset args :on_attach `check-conjure))
  (tset args :capabilities `caps)
  `((. lspc ,conf :setup) ,args))

(tset lsp-configs :cl-lsp {:default_config {:cmd [:cl-lsp]
                                            :filetypes [:lisp :commonlisp]
                                            :root_dir lspc.util.find_git_ancestor
                                            :single_file_support true}
                           :settings {}})

(var caps
     ((. (require :cmp_nvim_lsp) :default_capabilities) (vim.lsp.protocol.make_client_capabilities)))

(tset caps :textDocument :foldingRange
      {:dynamicRegistration false :lineFoldingOnly true})

;; Check if the buffer is a conjure log and stop the client if it is.
;; TODO: This doesn't work on popups, seems like on_attach isn't called.
(fn check-conjure [client buf]
  (when (vim.startswith (vim.fs.basename (vim.api.nvim_buf_get_name buf))
                        :conjure-)
    (client.stop)))

(fn disable-formatter [client _]
  (tset client :server_capabilities :documentFormattingRangeProvider false))

(setup :cl-lsp)
(setup :clangd {:on_attach (fn [c b] (disable-formatter c b)
                             (check-conjure c b))})

(setup :cssls)
(setup :elixirls {:cmd [:elixir-ls]})
(setup :eslint)
(setup :haxe_language_server)
(setup :html)
(setup :jsonls)
(setup :lua_ls {:settings {:Lua {:runtime {:version :LuaJIT
                                           :path (do
                                                   (var p
                                                        (vim.split package.path
                                                                   ";"))
                                                   (table.insert p :lua/?.lua)
                                                   (table.insert p
                                                                 :lua/?/init.lua))}
                                 :diagnostics {:globals [:vim]}
                                 :workspace [(vim.api.nvim_get_runtime_file ""
                                                                            true)]
                                 :telemetry {:enable false}}}})

(setup :ocamllsp)
(setup :prosemd_lsp)
(setup :racket_langserver)
(setup :rust_analyzer
       {:settings {:rust-analyzer {:checkOnSave {:command :clippy}}}})

(setup :taplo)
(setup :yamlls)
(setup :zls)
