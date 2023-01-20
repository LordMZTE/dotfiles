cg.addPath ".config"
cg.addPath ".local"
cg.addPath ".ssh"
cg.addPath ".cargo"

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
