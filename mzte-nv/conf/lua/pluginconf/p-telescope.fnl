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
                             :path_display [:truncate]}
                  :pickers {:find_files {:find_command [:fd
                                                        :--type
                                                        :f
                                                        :--strip-cwd-prefix
                                                        :--hidden]}}})

(telescope.load_extension :harpoon)

(set utils.transform_path
     (mztenv.telescope.makePathTransformer utils.transform_path))

(let [mopt mztenv.utils.map_opt
      lsp-opts {:fname_width 80 :show_line false}]
  (macro nmap [map action opt]
    `(vim.keymap.set :n ,map #(,action (themes.get_ivy ,opt)) mopt))
  ;; resume search
  (nmap :fr builtin.resume)
  ;; file finding mappings
  (nmap :ff builtin.find_files)
  (nmap :fg builtin.live_grep)
  ;; LSP mappings
  (nmap :gd builtin.lsp_definitions lsp-opts)
  (nmap :gi builtin.lsp_implementations lsp-opts)
  (nmap :gr builtin.lsp_references lsp-opts)
  (nmap :gs builtin.lsp_dynamic_workspace_symbols lsp-opts)
  (nmap :gp builtin.diagnostics {:bufnr 0})
  (nmap :gP builtin.diagnostics)
  ;; harpoon
  (nmap :gm ext.harpoon.marks))
