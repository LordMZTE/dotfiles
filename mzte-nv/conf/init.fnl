;; Preload mzte-nv
(set package.cpath (.. (. package :cpath) ";" (vim.loop.os_homedir)
                       :/.local/share/nvim/mzte-nv.so))

(let [(success mztenv) (pcall require :mzte_nv)]
  (when (not success)
    (error "Failed to preload mzte-nv. Is it installed?"))
  (mztenv.onInit))

;; Invoke the haxe config
(require :hx)
