(local nullls (require :null-ls))

(macro src [categ name]
  `(. nullls :builtins ,categ ,name))

(nullls.setup {:sources [(src :diagnostics :fish)
                         (src :diagnostics :tidy)
                         (src :formatting :clang_format)
                         (src :formatting :fish_indent)
                         (src :formatting :fnlfmt)
                         ((. (src :formatting :prettier) :with) {:extra_args (fn [params]
                                                                               (and params.options
                                                                                    params.options.tabSize
                                                                                    [:--tab-width
                                                                                     params.options.tabSize]))})
                         (src :formatting :shfmt)
                         (src :formatting :tidy)]})
