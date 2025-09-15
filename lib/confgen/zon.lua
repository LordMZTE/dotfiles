-- A rudimentary ZON serializer. Absolutely not robust.

local mod = {}

function mod.serialize(val)
    local typ = type(val)

    if typ == "nil" then
        return "null"
    elseif typ == "number" or typ == "boolean" then
        return tostring(val)
    elseif typ == "string" then
        return [["]] .. val .. [["]]
    elseif typ == "table" then
        if #val ~= 0 then
            local ret = ".{"
            for _, v in ipairs(val) do
                local serialized = mod.serialize(v)
                if serialized then
                    ret = ret .. serialized .. ","
                end
            end
            return ret .. "}"
        else
            local ret = ".{"
            for k, v in pairs(val) do
                local serialized = mod.serialize(v)
                if serialized then
                    ret = ret .. [[.@"]] .. k .. [["=]] .. serialized .. ","
                end
            end
            return ret .. "}"
        end
    end
end

return mod
