(local (harpoon mark ui)
       (values (require :harpoon) (require :harpoon.mark) (require :harpoon.ui)))

(harpoon.setup {})

(local mopt (. (require :mzte_nv) :utils :map_opt))
(vim.keymap.set :n :ma mark.toggle_file mopt)
(vim.keymap.set :n :mc mark.clear_all mopt)
(vim.keymap.set :n :mn ui.nav_next mopt)
(vim.keymap.set :n :mp ui.nav_prev mopt)
