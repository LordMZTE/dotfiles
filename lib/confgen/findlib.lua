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
    local profiles = os.getenv "NIX_PROFILES" or ""
    profiles = profiles .. " /usr /"

    for profile in profiles:gmatch "%S+" do
        local fpath = profile .. "/lib/" .. libname
        if fexists(fpath) then return fpath end
    end

    return nil
end
