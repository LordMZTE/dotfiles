(local lsps (require :lspsaga))

(local mztenv (require :mzte_nv))
(local catppuccin (require :catppuccin.groups.integrations.lsp_saga))

(lsps.setup {:ui {:kind (catppuccin.custom_kind) :code_action "󱐌" :actionfix "󱐌"}
             :lightbulb {:enable false}
             :code_action {:show_server_name true :extend_gitsigns true}})

(local lsps-codeaction (require :lspsaga.codeaction))
(local lsps-definition (require :lspsaga.definition))
(local lsps-diagnostic (require :lspsaga.diagnostic))
(local lsps-finder (require :lspsaga.finder))
(local lsps-hover (require :lspsaga.hover))
(local lsps-symbol (require :lspsaga.symbol))
(local lsps-rename (require :lspsaga.rename))

(vim.keymap.set :n :-a #(lsps-codeaction:code_action) mztenv.utils.map_opt)
(vim.keymap.set :n :<C-p> #(lsps-definition:init 1 1) mztenv.utils.map_opt)
(vim.keymap.set :n :-d #(lsps-diagnostic:goto_next) mztenv.utils.map_opt)
(vim.keymap.set :n :<C-g> #(lsps-finder:new []) mztenv.utils.map_opt)
(vim.keymap.set :n :K #(lsps-hover:render_hover_doc []) mztenv.utils.map_opt)
(vim.keymap.set :n :-o #(lsps-symbol:outline) mztenv.utils.map_opt)
(vim.keymap.set :n :-n #(lsps-rename:lsp_rename []) mztenv.utils.map_opt)
