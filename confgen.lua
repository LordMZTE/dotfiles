cg.addPath ".config"
cg.addPath ".local"
cg.addPath ".ssh"
cg.addPath ".cargo"
cg.addPath "etc"

for k, v in pairs(require "cg_opts") do
    cg.opt[k] = v
end

-- This function is called in templates to allow adding device-specific configs.
cg.opt.getDeviceConf = function(id)
    local path = os.getenv "HOME" .. "/.config/mzte_localconf/" .. id
    local file = io.open(path, "r")

    if file == nil then
        return ""
    end

    return file:read "*a"
end

-- Get the output of a system command
cg.opt.system = function(cmd)
    local handle = io.popen(cmd)
    if handle == nil then
        error("Failed to spawn process" .. cmd)
    end
    return handle:read("*a"):gsub("%s+", "")
end
