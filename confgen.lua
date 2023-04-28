cg.addPath ".config"
cg.addPath ".local"
cg.addPath ".ssh"
cg.addPath ".cargo"
cg.addPath "etc"

cg.addFile ".Xresources.cgt"

-- Recursively merge 2 tables
local function merge(a, b)
    for k, v in pairs(b) do
        if type(v) == "table" and type(a[k]) == "table" then
            merge(a[k], v)
        else
            a[k] = v
        end
    end
    return a
end

cg.opt = merge(cg.opt, require "cg_opts")

-- This function is called in templates to allow adding device-specific configs.
cg.opt.getDeviceConf = function(id)
    local path = os.getenv "HOME" .. "/.config/mzte_localconf/" .. id
    local file = io.open(path, "r")

    if file == nil then
        return ""
    end

    return file:read "*a"
end

local local_opts = loadfile(os.getenv "HOME" .. "/.config/mzte_localconf/opts.lua")

if local_opts then
    cg.opt = merge(cg.opt, local_opts())
end

-- Get the output of a system command
cg.opt.system = function(cmd)
    local handle = io.popen(cmd)
    if handle == nil then
        error("Failed to spawn process" .. cmd)
    end
    return handle:read("*a"):gsub("%s+", "")
end

-- Compile the input as lua. Meant to be used as a post-processor.
cg.opt.luaCompile = function(lua)
    return string.dump(loadstring(lua), true)
end

-- Compile the input as fennel. Meant to be used as a post-processor.
cg.opt.fennelCompile = function(fnl)
    local handle = io.popen("fennel -c - > /tmp/cgfnl", "w")
    if handle == nil then
        error "Failed to spawn fennel"
    end

    handle:write(fnl)
    handle:close()

    local f = io.open "/tmp/cgfnl"
    local res = f:read "*a"
    f:close()
    return res
end

-- Check if the given file exists
cg.opt.fileExists = function(path)
    local f = io.open(path, "r")

    if f then
        f:close()
        return true
    end

    return false
end
