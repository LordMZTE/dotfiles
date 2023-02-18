(local nullls (require :null-ls))

(macro src [categ name]
  `(. nullls :builtins ,categ ,name))

(nullls.setup {:sources [(src :code_actions :gitsigns)
                         (src :code_actions :shellcheck)
                         (src :diagnostics :fish)
                         (src :diagnostics :shellcheck)
                         (src :diagnostics :tidy)
                         ;; a shitty python formatter
                         ;; TODO: remove once done with involuntary python classes
                         (src :formatting :black)
                         (src :formatting :clang_format)
                         (src :formatting :fish_indent)
                         (src :formatting :fnlfmt)
                         (src :formatting :prettier)
                         (src :formatting :raco_fmt)
                         (src :formatting :shfmt)
                         (src :formatting :stylua)
                         (src :formatting :tidy)]})
