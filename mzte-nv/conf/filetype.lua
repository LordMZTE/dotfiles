vim.filetype.add {
    extension = {
        cgt = function(path, bufnr)
            local trimmed = path:gsub(".cgt$", "")
            return vim.filetype.match { filename = trimmed, bufnr = bufnr }
        end,

        -- nvim defaults to scheme
        rkt = "racket",
        rktd = "racket",
        rktl = "racket",
    },
}
