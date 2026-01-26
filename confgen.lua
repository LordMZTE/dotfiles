cg.addPath "cgassets"

cg.addPath ".config"
cg.addPath ".julia"
cg.addPath ".librewolf"
cg.addPath ".local"
cg.addPath ".ssh"
cg.addPath ".cargo"
cg.addPath "etc"

cg.addFile ".Xresources.cgt"
cg.addFile ".bashrc"
cg.addFile ".clang-format.cgt"
cg.addFile ".gtkrc-2.0.cgt"
cg.addFile ".inputrc"
cg.addFile ".stylua.toml.cgt"
cg.addFile "hxformat.json.cgt"

cg.onDone(function(errors)
    if errors then
        print "ERRORS DURING CONFGEN"
    else
        print "updating dconf"
        cg.opt.system "dconf load / <~/confgenfs/cgassets/dconf.ini"
    end
end)

if cg.fs then
    -- Cache files in ConfgenFS for 5 seconds by default
    cg.fs.cachetime = 5 * 1000
end

local nix = (loadfile "nix/cgnix/nix.lua" or function()
    print "no cgnix file!"
    return {}
end)()

cg.opt.nix = nix

local fennel = (loadfile(nix["fennel.lua"] or "/usr/share/lua/5.4/fennel.lua")())

-- This function is called in templates to allow adding device-specific configs.
cg.opt.getDeviceConf = function(id)
    local path = os.getenv "HOME" .. "/.config/mzte_localconf/" .. id
    local file = io.open(path, "r")

    if not file then return "" end

    return file:read "*a"
end

-- Returns the contents of a file
cg.opt.read = function(fname)
    local file = io.open(fname, "r")
    if not file then return nil end

    return file:read "*a"
end

-- Get the output of a system command
cg.opt.system = function(cmd)
    local handle = io.popen(cmd)
    if handle == nil then error("Failed to spawn process" .. cmd) end
    local data, _ = handle:read("*a"):gsub("%s$", "")
    handle:close()
    return data
end

-- Compile the input as lua. Meant to be used as a post-processor.
cg.opt.luaCompile = function(lua) return string.dump(loadstring(lua), true) end

-- Compile the input as fennel. Meant to be used as a post-processor.
cg.opt.fennelCompile = fennel.compileString

-- Evaluate fennel code and JSONify the result. Meant to be used as a post-processor.
cg.opt.fennelToJSON = function(str) return cg.fmt.json.serialize(fennel.eval(str)) end

-- Check if the given file exists
cg.opt.fileExists = function(path)
    local f = io.open(path, "r")

    if f then
        f:close()
        return true
    end

    return false
end

-- Check if a TERM environment variable describes a terminal supporting the kitty image protocol.
cg.opt.termSupportsKittyImages = function(term)
    if not term then return false end
    return term:match "kitty" or term:match "ghostty"
end

-- Returns true iff the given terminal command line (usually the return value of fsctx:getCallerCmd)
-- should cause a terminal to be launched with a larger font size.
cg.opt.shouldUseLargeFontForCmdline = function(cmdline)
    return cg.lib.contains(cmdline, function(arg)
        return arg:match "iamb$"
    end)
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

-- This will set a "safe mode" flag which prevents supported messenger apps from showing images.
-- Useful for opening matrix in public spaces due to recent spam.
cg.opt.toggleSafeMode = function()
    cg.opt.safe_mode = not cg.opt.safe_mode
    if cg.opt.safe_mode then
        cg.opt.system [[notify-send -a "MZTE System" "Safe mode enabled"]]
    else
        cg.opt.system [[notify-send -a "MZTE System" "Safe mode disabled"]]
    end
end

-- Essentially undoes all cached "require" calls. This is useful for iterating on code running in
-- ConfgenFS to reload.
cg.opt.unloadModules = function()
    for k, _ in pairs(package.loaded) do
        package.loaded[k] = nil
    end
end

require "cg_opts"
require "cg_lazies"

local local_opts = loadfile(os.getenv "HOME" .. "/.config/mzte_localconf/opts.lua")

if local_opts then local_opts() end
