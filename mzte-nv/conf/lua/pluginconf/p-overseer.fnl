(local overseer (require :overseer))
(local kmopts (. (require :mzte_nv) :utils :map_opt))

(overseer.setup {:templates [:builtin]})

(vim.keymap.set :n :TO overseer.toggle kmopts)
