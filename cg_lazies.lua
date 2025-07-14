-- This file acts as a collection of shared lazy objects used in configuration files.

cg.opt.lazy = {}
cg.opt.lazy.mpvCodecs = cg.lib.lazy(function()
    local mpv_codecs = {}
    local cmdout = cg.opt.system "mpv --no-config --vd=help"
    for codec in cmdout:gmatch "    ([^ ]+).-%- .-\n" do
        if
            -- These are obsolete for hardware decoding
            not codec:match "_cuvid$" and not codec:match "_vdpau$"
        then
            table.insert(mpv_codecs, codec)
        end
    end
    return mpv_codecs
end)

cg.opt.lazy.unameORS = cg.lib.lazy(function() return cg.opt.system "uname -ors" end)
cg.opt.lazy.username = cg.lib.lazy(function() return cg.opt.system "whoami" end)
cg.opt.lazy.ncpus = cg.lib.lazy(function() return tonumber(cg.opt.system "nproc") end)
