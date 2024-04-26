(local lspp (require :lsp-progress))
(local mztenv (require :mzte_nv))

(lspp.setup {:regular_internal_update_time 1000
             :spinner mztenv.reg.spinner
             :decay 2000
             :series_format mztenv.lsp_progress.formatSeries
             :client_format mztenv.lsp_progress.formatClient
             :format #{:msg (table.concat $1 " ")}})
