(local mztenv (require :mzte_nv))
(local lspc (require :lspconfig))
(local util (require :lspconfig.util))
(local lsp-configs (require :lspconfig.configs))

(macro setup [conf args]
  (var args args)
  (when (not args)
    (set args {}))
  (tset args :on_attach (if args.on_attach
                            `(fn [client# bufnr#]
                               (mztenv.lsp.onAttach client# bufnr#)
                               (,args.on_attach client# bufnr#))
                            `mztenv.lsp.onAttach))
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

(tset caps :offsetEncoding [:utf-8])

(fn disable-formatter [client _]
  (tset client :server_capabilities :documentFormattingRangeProvider false))

(setup :cl-lsp)
(setup :clangd {:on_attach disable-formatter})

(setup :cssls)
(setup :elixirls {:cmd [:elixir-ls]})
(setup :eslint)
(setup :glsl_analyzer)
(setup :haxe_language_server)
(setup :html)
(setup :jsonls {:on_attach disable-formatter})
(setup :julials)
(setup :ltex {:cmd [:ltex-ls-plus]
              ;; LTeX is slow and noisy, but still catches a few errors sometimes.
              :autostart false
              :filetypes [:asciidoc
                          :bib
                          :context
                          :gitcommit
                          :html
                          :mail
                          :markdown
                          :org
                          :pandoc
                          :plaintex
                          :quarto
                          :rmd
                          :rnoweb
                          :rst
                          :tex
                          :text
                          :typst
                          :xhtml]
              :settings {:ltex {:enabled [:typst
                                          :bibtex
                                          :gitcommit
                                          :markdown
                                          :org
                                          :tex
                                          :restructuredtext
                                          :rsweave
                                          :latex
                                          :quarto
                                          :rmd
                                          :context
                                          :html
                                          :xhtml
                                          :mail
                                          :plaintext]}}})

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

(setup :nil_ls {:settings {:nil {:formatting {:command [:nixpkgs-fmt]}}}})
(setup :openscad_lsp)
(setup :racket_langserver)
(setup :rust_analyzer
       {:settings {:rust-analyzer {:checkOnSave {:command :clippy}}}})

(setup :taplo)
(setup :tinymist
       {:single_file_support true
        :root_dir (util.root_pattern :.typstroot)
        :settings {:formatterMode :typstyle :formatterPrintWidth 100}})

(setup :zls)
