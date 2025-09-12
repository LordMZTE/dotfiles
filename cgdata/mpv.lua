return {
    codecs = cg.lib.lazy(function()
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
}
