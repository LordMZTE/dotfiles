-- This module is responsible for loading the native mzte-nv lua module
package.cpath = package.cpath .. ";" .. vim.loop.os_homedir() .. "/.local/share/nvim/mzte-nv.so"

local success = pcall(require, "mzte_nv");
if not success then
    error "Failed to preload mzte-nv. Is it installed?"
end

require("mzte_nv").onInit()
