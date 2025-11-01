(local ts-textobjects (require :nvim-treesitter-textobjects))
(local select (require :nvim-treesitter-textobjects.select))

(ts-textobjects.setup {})

(fn mk-textobject [map textobj]
  (vim.keymap.set [:x :o] map #(select.select_textobject textobj :textobjects)))

(mk-textobject :a$ "@math.outer")
(mk-textobject :i$ "@math.inner")
(mk-textobject :af "@function.outer")
(mk-textobject :if "@function.inner")
(mk-textobject :ac "@class.outer")
(mk-textobject :ic "@class.inner")
