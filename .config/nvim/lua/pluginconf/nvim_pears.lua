local pears = require "pears"

pears.setup(function(conf)
    conf.preset "tag_matching"

    conf.on_enter(function(pears_handle)
        if vim.fn.pumvisible() == 1 then
            return vim.fn["coc#_select_confirm"]()
        else
            pears_handle()
        end
    end)
end)
