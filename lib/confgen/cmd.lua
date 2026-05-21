--- A data structure to represent a command, either a shell command or argv.
--- This is useful to represent commands that may be used in either form.

local M = {}

--- @class Cmd
--- @field sh? string
--- @field argv? string[]
local Cmd = { _type = "Cmd" }
Cmd.__index = Cmd

--- Turn this command to a shell command.  You should use this if only shell commands are supported,
--- otherwise either use `toArgv` or handle both cases.
--- @return string
--- @nodiscard
function Cmd:toSh()
    if self.sh then return self.sh end

    -- Shell escape the arguments.
    local function shellEscape(arg)
        arg = string.gsub(arg, "'", "\\'")

        if string.match(arg, "[ \"]") then
            arg = "'" .. arg .. "'"
        end

        return arg
    end

    return table.concat(cg.lib.map(self.argv, shellEscape), " ")
end

--- Turn this command to an argv vector.  You should use this if argv commands are supported,
--- otherwise either use `toShell` or handle both cases.
--- @return string[]
--- @nodiscard
function Cmd:toArgv()
    if self.argv then return self.argv end

    -- Shell out if this is a shell command
    return { "sh", "-c", self.sh }
end

function Cmd:zonSerialize()
    local zon = require "lib.confgen.zon"
    return zon.serialize(self:toSh())
end

--- Construct a shell command
--- @param shellcmd string The shell command as string
--- @return Cmd a command object
--- @nodiscard
function M.sh(shellcmd)
    local cmd = { sh = shellcmd }
    setmetatable(cmd, Cmd)
    return cmd
end

--- Construct an argv command
--- @param argvcmd string[] The shell command as string
--- @return Cmd a command object
--- @nodiscard
function M.argv(argvcmd)
    local cmd = { argv = argvcmd }
    setmetatable(cmd, Cmd)
    return cmd
end

return M
