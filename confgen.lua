cg.addPath "cgassets"

cg.addPath ".config"
cg.addPath ".librewolf"
cg.addPath ".local"
cg.addPath ".ssh"
cg.addPath ".cargo"
cg.addPath "etc"

cg.addFile ".bashrc"
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
        cg.opt.system('gsettings set org.gnome.desktop.interface font-name "' .. cg.opt.font .. ' 11"')
    end
end)

local nix = (loadfile "nix/cgnix/nix.lua" or function()
    print "no cgnix file!"
    return {}
end)()

cg.opt.nix = nix

local fennel = (loadfile(nix["fennel.lua"] or "/usr/share/lua/5.4/fennel.lua")())

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
cg.opt.fennelCompile = fennel.compileString

-- Evaluate fennel code and JSONify the result. Meant to be used as a post-processor.
cg.opt.fennelToJSON = function(str)
    return cg.fmt.json.serialize(fennel.eval(str))
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

-- Set the currently active wayland compositor. Updates options for templates as well as gsettings.
cg.opt.setCurrentWaylandCompositor = function(comp)
    cg.opt.wayland_compositor = comp
    if comp == "river" then
        cg.opt.system 'gsettings set org.gnome.desktop.wm.preferences button-layout ""'
    else
        cg.opt.system "gsettings reset org.gnome.desktop.wm.preferences button-layout"
    end
end

cg.opt = merge(cg.opt, require "cg_opts")

local local_opts = loadfile(os.getenv "HOME" .. "/.config/mzte_localconf/opts.lua")

if local_opts then
    cg.opt = merge(cg.opt, local_opts())
end
