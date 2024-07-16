(local mztenv (require :mzte_nv))

;; Use 2-space indentation for nix
(set vim.o.shiftwidth 2)
(set vim.o.tabstop 2)

;; FF to prefetch
(vim.keymap.set :n :FF (. (require :nix-update) :prefetch_fetch) mztenv.utils.map_opt)
