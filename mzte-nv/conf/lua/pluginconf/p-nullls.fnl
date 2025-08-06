(local nullls (require :null-ls))

(macro src [categ name]
  `(. nullls :builtins ,categ ,name))

(nullls.setup {:sources [(src :diagnostics :fish)
                         (src :diagnostics :tidy)
                         (src :formatting :clang_format)
                         (src :formatting :fish_indent)
                         (src :formatting :fnlfmt)
                         (src :formatting :prettier)
                         (src :formatting :shfmt)
                         (src :formatting :tidy)]})
