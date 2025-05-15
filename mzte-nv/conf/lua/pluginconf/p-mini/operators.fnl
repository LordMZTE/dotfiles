(local ops (require :mini.operators))
(ops.setup {:exchange {:prefix :gs}
            :replace {:prefix :gr}
            :evaluate {:prefix ""}
            :multiply {:prefix ""}
            :sort {:prefix ""}})
