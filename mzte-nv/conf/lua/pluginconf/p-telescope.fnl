(local (telescope builtin ext themes)
       (values (require :telescope) (require :telescope.builtin)
               (. (require :telescope._extensions) :manager)
               (require :telescope.themes)))

(telescope.setup {:defaults {:vimgrep_arguments [:rg
                                                 :--color=never
                                                 :--no-heading
                                                 :--with-filename
                                                 :--line-number
                                                 :--column
                                                 :--smart-case
                                                 :--hidden]}
                  :pickers {:find_files {:find_command [:fd
                                                        :--type
                                                        :f
                                                        :--strip-cwd-prefix
                                                        :--hidden]}}})

(telescope.load_extension :harpoon)

(let [mopt (. (require :mzte_nv) :utils :map_opt)]
  (macro nmap [map action opt]
    `(vim.keymap.set :n ,map #(,action (themes.get_ivy ,opt)) mopt))
  ;; resume search
  (nmap :fr builtin.resume)
  ;; file finding mappings
  (nmap :ff builtin.find_files)
  (nmap :fg builtin.live_grep)
  ;; LSP mappings
  (nmap :gd builtin.lsp_definitions)
  (nmap :gi builtin.lsp_implementations)
  (nmap :gr builtin.lsp_references)
  (nmap :gs builtin.lsp_dynamic_workspace_symbols)
  (nmap :gp builtin.diagnostics {:bufnr 0})
  (nmap :gP builtin.diagnostics)
  ;; harpoon
  (nmap :gm ext.harpoon.marks))
