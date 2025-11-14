xplr.fn.exec = {}
function xplr.fn.exec.appendFocused(ctx)
    return {
        { BufferInput = xplr.util.shell_escape(ctx.focused_node.absolute_path) .. " " },
    }
end

function xplr.fn.exec.appendSelection(ctx)
    local to_append = ""
    for _, node in ipairs(ctx.selection) do
        to_append = to_append .. xplr.util.shell_escape(node.absolute_path) .. " "
    end

    return {
        { BufferInput = to_append },
    }
end

xplr.config.modes.custom.exec = {
    name = "exec",
    key_bindings = {
        on_key = {
            ["ctrl-i"] = {
                help = "insert focused file",
                messages = {
                    { CallLuaSilently = "exec.appendFocused" },
                },
            },

            ["alt-i"] = {
                help = "insert selection",
                messages = {
                    { CallLuaSilently = "exec.appendSelection" },
                },
            },

            ["enter"] = {
                help = "submit",
                messages = {
                    {
                        BashExec0 = [===[
                            eval "${XPLR_INPUT_BUFFER}"
                            read -p "[press enter to continue]"
                        ]===]
                    }, "PopMode"
                }
            }
        },

        default = {
            messages = {
                "UpdateInputBufferFromKey",
            }
        }
    },
}

-- Workaround for terminal weirdness
xplr.config.modes.custom.exec.key_bindings.on_key["tab"] =
    xplr.config.modes.custom.exec.key_bindings.on_key["ctrl-i"]

xplr.config.modes.builtin.default.key_bindings.on_key[";"] = {
    help = "exec mode",
    messages = {
        { SwitchModeCustom = "exec" },
    },
}

xplr.config.modes.builtin.default.key_bindings.on_key["o"] = {
    help = "exec focused",
    messages = {
        { SwitchModeCustom = "exec" },
        { BufferInput = " " },
        { CallLuaSilently = "exec.appendFocused" },
        { UpdateInputBuffer = "GoToStart" },
    },
}

xplr.config.modes.builtin.default.key_bindings.on_key["O"] = {
    help = "exec selection",
    messages = {
        { SwitchModeCustom = "exec" },
        { BufferInput = " " },
        { CallLuaSilently = "exec.appendSelection" },
        { UpdateInputBuffer = "GoToStart" },
    },
}
