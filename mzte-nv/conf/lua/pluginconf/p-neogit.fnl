(local ngit (require :neogit))

(ngit.setup {;; This always trips while entering the PGP password for signing
             :console_timeout 100000})

(vim.api.nvim_create_user_command :Neog ngit.open {:nargs 0})
