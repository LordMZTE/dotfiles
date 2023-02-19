(local ngit (require :neogit))

(ngit.setup {})

(vim.api.nvim_create_user_command :Neogit ngit.open {:nargs 0})
