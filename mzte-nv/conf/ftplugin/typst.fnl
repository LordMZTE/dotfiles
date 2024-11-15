;; Use 2-space indentation for typst
(set vim.o.shiftwidth 2)
(set vim.o.tabstop 2)

(let [cb (fn [p]
           (let [Terminal (. (require :toggleterm.terminal) :Terminal)
                 lspc-util (require :lspconfig.util)
                 file (vim.api.nvim_buf_get_name 0)
                 outfile (.. :/tmp/
                             (string.gsub (vim.fs.basename file) "%.typ$" :.pdf))
                 root ((lspc-util.root_pattern :.typstroot) file)
                 term (Terminal:new {:direction :horizontal
                                     :cmd (if root
                                              (.. "typst watch --root " root
                                                  " " file " " outfile)
                                              (.. "typst watch " file " "
                                                  outfile))})]
             (term:toggle)
             (vim.uv.spawn :zathura {:args [outfile]}
                           (fn [code signal] (term:shutdown)))))]
  (vim.api.nvim_create_user_command :TypstWatch cb {:nargs 0}))
