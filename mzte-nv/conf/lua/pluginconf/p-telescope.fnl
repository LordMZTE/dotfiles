(local (mztenv telescope utils builtin ext themes)
       (values (require :mzte_nv) (require :telescope)
               (require :telescope.utils) (require :telescope.builtin)
               (. (require :telescope._extensions) :manager)
               (require :telescope.themes)))

(telescope.setup {:defaults {:vimgrep_arguments [:rg
                                                 :--color=never
                                                 :--no-heading
                                                 :--with-filename
                                                 :--line-number
                                                 :--column
                                                 :--smart-case
                                                 :--hidden]
                             :path_display [:truncate :filename_first]}
                  :pickers {:find_files {:find_command [:fd
                                                        :--type
                                                        :f
                                                        :--strip-cwd-prefix
                                                        :--hidden]}}})

(telescope.load_extension :harpoon)

(set utils.transform_path
     (mztenv.telescope.makePathTransformer utils.transform_path))

(macro nmap [map action opt]
  `(vim.keymap.set :n ,map #(,action (themes.get_ivy ,opt))
                   mztenv.utils.map_opt))

(macro lsp-map [suffix action extra-opts]
  (local opt {:fname_width 80 :show_line false})
  (each [k v (pairs (or extra-opts {}))]
    (tset opt k v))
  `(do
     (nmap ,(.. :g suffix) ,action ,opt)
     (nmap ,(.. :gn suffix) ,action
           ,(doto (collect [k v (pairs opt)] k v)
              (tset :jump_type :tab)))
     (nmap ,(.. :gs suffix) ,action
           ,(doto (collect [k v (pairs opt)] k v)
              (tset :jump_type :split)))
     (nmap ,(.. :gv suffix) ,action
           ,(doto (collect [k v (pairs opt)] k v)
              (tset :jump_type :vsplit)))))

;; resume search
(nmap :fr builtin.resume)
;; file finding mappings
(nmap :ff builtin.find_files)
(nmap :fg builtin.live_grep)
;; LSP mappings
(lsp-map :d builtin.lsp_definitions)
(lsp-map :i builtin.lsp_implementations)
(lsp-map :r builtin.lsp_references)
(lsp-map :s builtin.lsp_dynamic_workspace_symbols)
(lsp-map :p builtin.diagnostics {:bufnr 0})
(lsp-map :P builtin.diagnostics)
;; harpoon
(nmap :gm ext.harpoon.marks)
