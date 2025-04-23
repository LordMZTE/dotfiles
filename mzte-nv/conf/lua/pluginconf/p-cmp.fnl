(local (cmp luasnip mztenv)
       (values (require :cmp) (require :luasnip) (require :mzte_nv)))

(local sources {:buffer " "
                :luasnip " "
                :nvim_lsp " "
                :path " "
                :treesitter " "
                :lua-latex-symbols " "})

(cmp.setup {:snippet {:expand #(luasnip.lsp_expand (. $1 :body))}
            :mapping {:<C-b> (cmp.mapping (cmp.mapping.scroll_docs -4) [:i :c])
                      :<C-f> (cmp.mapping (cmp.mapping.scroll_docs 4) [:i :c])
                      :<C-Space> (cmp.mapping (cmp.mapping.complete) [:i :c])
                      :<Tab> (cmp.mapping mztenv.cmp.onTab [:i :s])
                      :<S-Tab> (cmp.mapping (cmp.mapping.select_prev_item))
                      :<C-Tab> (cmp.mapping #(if (luasnip.expand_or_jumpable)
                                                 (luasnip.expand_or_jump)
                                                 ($1))
                                            [:i :s])
                      :<CR> (cmp.mapping.confirm {:select true})}
            :sources (cmp.config.sources (icollect [n _ (pairs sources)]
                                           {:name n}))
            :formatting {:format (fn [entry vim-item]
                                   (tset vim-item :menu
                                         (. sources entry.source.name))
                                   vim-item)}
            :experimental {:ghost_text true}})

(cmp.setup.cmdline "/" {:sources {:name :buffer}})
(cmp.setup.cmdline ":"
                   {:sources (cmp.config.sources [{:name :path}]
                                                 [{:name :cmdline}])})

(local signs {:Error " " :Warn " " :Hint " " :Info " "})

(each [k v (pairs signs)]
  (let [hl (.. :DiagnosticSign k)]
    (vim.fn.sign_define hl {:text v :texthl hl :numhl hl})))
