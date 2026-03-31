local function fexists(p)
    local f = io.open(p, "r")
    if f then
        io.close(f)
        return true
    end
    return false
end

-- Try to locate a shared library of the given name installed on the system.
return function(libname)
    local prefixes = {
        "/run/current-system/sw",
        "/usr",
        "",
    }
    for _, pfx in ipairs(prefixes) do
        local fpath = pfx .. "/lib/" .. libname
        if fexists(fpath) then return fpath end
    end

    return nil
end
