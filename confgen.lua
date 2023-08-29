cg.addPath ".config"
cg.addPath ".local"
cg.addPath ".ssh"
cg.addPath ".cargo"
cg.addPath "etc"

cg.addFile ".gtkrc-2.0.cgt"
cg.addFile ".Xresources.cgt"
cg.addFile ".replrc"
cg.addFile ".vieterrc.cgt"

cg.onDone(function(errors)
    if errors then
        print "ERRORS DURING CONFGEN"
    else
        print "updating gsettings"
        cg.opt.system("gsettings set org.gnome.desktop.interface icon-theme " .. cg.opt.icon_theme)
        cg.opt.system("gsettings set org.gnome.desktop.interface gtk-theme " .. cg.opt.gtk_theme)
        cg.opt.system("gsettings set org.gnome.desktop.interface cursor-theme " .. cg.opt.cursor.theme)
        cg.opt.system("gsettings set org.gnome.desktop.interface cursor-size " .. cg.opt.cursor.size)
    end
end)

-- Recursively merge 2 tables
local function merge(a, b)
    if b[1] then -- b is a list
        return b
    end

    for k, v in pairs(b) do
        if type(v) == "table" and type(a[k]) == "table" then
            a[k] = merge(a[k], v)
        else
            a[k] = v
        end
    end
    return a
end

cg.opt = merge(cg.opt, require "cg_opts")

local local_opts = loadfile(os.getenv "HOME" .. "/.config/mzte_localconf/opts.lua")

if local_opts then
    cg.opt = merge(cg.opt, local_opts())
end

-- This function is called in templates to allow adding device-specific configs.
cg.opt.getDeviceConf = function(id)
    local path = os.getenv "HOME" .. "/.config/mzte_localconf/" .. id
    local file = io.open(path, "r")

    if not file then
        return ""
    end

    return file:read "*a"
end

-- Returns the contents of a file
cg.opt.read = function(fname)
    local file = io.open(fname, "r")
    if not file then
        return nil
    end

    return file:read "*a"
end

-- Get the output of a system command
cg.opt.system = function(cmd)
    local handle = io.popen(cmd)
    if handle == nil then
        error("Failed to spawn process" .. cmd)
    end
    local data, _ = handle:read("*a"):gsub("%s$", "")
    return data
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
