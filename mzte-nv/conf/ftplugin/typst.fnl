;; Use 2-space indentation for typst
(set vim.o.shiftwidth 2)
(set vim.o.tabstop 2)

(let [cb (fn [p]
           (let [Terminal (. (require :toggleterm.terminal) :Terminal)
                 lspc-util (require :lspconfig.util)
                 file (vim.api.nvim_buf_get_name 0)
                 outfile-base (.. :typstwatch_
                                  (string.gsub (vim.fs.basename file) "%.typ$"
                                               :.pdf))
                 outfile (.. :/tmp/ outfile-base)
                 root ((lspc-util.root_pattern :.typstroot) file)
                 term (Terminal:new {:direction :horizontal
                                     :cmd (if root
                                              (.. "typst watch --root " root
                                                  " " file " " outfile)
                                              (.. "typst watch " file " "
                                                  outfile))})
                 fsev (vim.uv.new_fs_event)
                 on-file-appear (fn [err file events]
                                  (when (and (not err) (= file outfile-base))
                                    (fsev:stop)
                                    (vim.uv.spawn :zathura {:args [outfile]}
                                                  (fn [code signal]
                                                    (vim.uv.fs_unlink outfile
                                                                      #(if $1
                                                                           (error "Deleting output: "
                                                                                  $1)))
                                                    (vim.schedule #(term:shutdown))))))]
             (fsev:start :/tmp {} on-file-appear)
             (term:open)))]
  (vim.api.nvim_create_user_command :TypstWatch cb {:nargs 0}))

(local mini-pairs (require :mini.pairs))
(mini-pairs.map_buf 0 :i "$" {:action :closeopen :pair "$$"})
