local map = vim.api.nvim_set_keymap
local dap = require "dap"
local dapui = require "dapui"

dapui.setup {}

dap.adapters.lldb = {
    type = "executable",
    -- TODO: hardcoding the path here is total dog shit
    -- I should implement a dap module in mzte-nv that resolves this.
    command = "/usr/bin/lldb-vscode", -- included in lldb package
    name = "lldb",
}

dap.configurations.c = {
    {
        name = "Launch",
        type = "lldb",
        request = "launch",
        program = function()
            return vim.fn.input "Binary: "
        end,
        cwd = "${workspaceFolder}",
        stopOnEntry = false,
        args = function()
            return vim.split(vim.fn.input "Args: ", " ")
        end,
        runInTerminal = true,
    },
}

dap.configurations.cpp = dap.configurations.c

-- TODO: maybe some way to discover the executable here with cargo n stuff?
dap.configurations.rust = dap.configurations.c
dap.configurations.zig = dap.configurations.c

dap.configurations.java = {
    {
        type = "java",
        request = "attach",
        name = "Java attach",
        hostName = "127.0.0.1",
        port = 5005,
    },
}

local opts = { noremap = true, silent = true }
map("n", "fu", [[<cmd>lua require("dapui").toggle()<CR>]], opts)
map("n", "fb", [[<cmd>lua require("dap").toggle_breakpoint()<CR>]], opts)
map("n", "fc", [[<cmd>lua require("dap").continue()<CR>]], opts)
map("n", "fn", [[<cmd>lua require("dap").step_over()<CR>]], opts)
map("n", "fi", [[<cmd>lua require("dap").step_into()<CR>]], opts)
map("n", "fo", [[<cmd>lua require("dap").step_out()<CR>]], opts)
