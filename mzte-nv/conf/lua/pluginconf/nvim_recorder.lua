require("recorder").setup {
    mapping = {
        -- this would conflict with search keybind (default is #)
        addBreakPoint = nil,
    },
    -- clear all existing macros on startup
    clear = true,
}
