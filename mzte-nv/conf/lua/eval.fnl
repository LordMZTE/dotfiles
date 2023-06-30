(local fnl-eval (. (require :mzte_nv) :fennel :eval))
(vim.api.nvim_create_user_command :Fnl
                                  (fn [args] (vim.print (fnl-eval args.args)))
                                  {:nargs "+"})

(fn insert-at-cursor [txt]
  (let [[_ row col _ _] (vim.fn.getcurpos)
        rpos {:line (- row 1) :character (- col 1)}
        range {:start rpos :end rpos}]
    (vim.lsp.util.apply_text_edits [{: range :newText (tostring txt)}] 0 :utf-8)))

;; Fennel Eval
(vim.keymap.set :i :<C-f>
                (fn []
                  (vim.ui.input {:prompt "fnleval> "}
                                (fn [inp]
                                  (insert-at-cursor (fnl-eval inp))))))

;; Lua Eval
(vim.keymap.set :i :<C-l>
                (fn []
                  (vim.ui.input {:prompt "luaeval> "}
                                (fn [inp]
                                  (insert-at-cursor (vim.fn.luaeval inp))))))
