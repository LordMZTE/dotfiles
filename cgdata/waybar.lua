local mod = {}

-- Maximum length for text modules
local max_length = 32

local bar_icons = { " ", "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█" }

-- This is a function so we can re-execute it when the compositor changes.
function mod.modulesLeft()
    if cg.opt.wayland_compositor == "river" then
        return { "river/tags", "river/window" }
    elseif cg.opt.wayland_compositor == "hyprland" then
        return { "hyprland/workspaces", "hyprland/window" }
    else
        return {}
    end
end

mod.modules_right = {
    "mpris",
    "cpu",
    "memory",
    "network",
    "temperature",
    "pulseaudio",
    "battery",
    "clock",
    "tray",
}

function mod.moduleConfig()
    local conf = {}

    if cg.opt.wayland_compositor == "river" then
        -- "S" for scratchpad
        local labels = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "S" }
        conf["river/tags"] = {
            ["num-tags"] = #labels,
            ["tag-labels"] = labels,
            ["hide-vacant"] = true,
        }

        conf["river/window"] = {
            ["max-length"] = max_length,
        }
    end

    conf["mpris"] = {
        format = "{status_icon} {dynamic}",
        interval = 5,
        ["dynamic-order"] = { "title", "artist", "position", "length" },
        ["dynamic-importance-order"] = { "position", "length", "artist", "album" },
        ["status-icons"] = { playing = "󰏤", paused = "󰐊", stopped = "󰓛" },
        ["title-len"] = max_length / 2,
        ["dynamic-len"] = max_length,
        ["dynamic-separators"] = " 󱓜 "
    }

    conf["tray"] = { spacing = 10 }

    conf["clock"] = {
        ["tooltip-format"] = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>",
        ["format-alt"] = "{:%Y-%m-%d}",
    }

    local cpu_format = ""
    for i = 0, cg.opt.lazy.ncpus() - 1 do
        cpu_format = cpu_format .. "{icon" .. i .. "}"
    end
    cpu_format = cpu_format .. " {usage}% {max_frequency} {avg_frequency}⌀  "
    conf["cpu"] = {
        format = cpu_format,
        interval = 2,
        ["format-icons"] = bar_icons,
    }

    conf["memory"] = {
        format = "{}%  ",
    }

    local function isCPUHwmon(name)
        -- k10temp is for some AMD CPUs.
        return name == "coretemp" or name == "k10temp"
    end
    local cpu_temp_hwmon = nil
    for d in require("lfs").dir("/sys/class/hwmon") do
        if d ~= "." and d ~= ".." then
            local namef = io.open("/sys/class/hwmon/" .. d .. "/name", "r")

            if isCPUHwmon(namef:read("*a"):gsub("%s+", "")) then
                cpu_temp_hwmon = "/sys/class/hwmon/" .. d .. "/temp1_input"
                break
            end

            namef:close()
        end
    end
    conf["temperature"] = {
        ["hwmon-path"] = cpu_temp_hwmon,
        ["critical-threshold"] = 95,
        ["warning-threshold"] = 80,
        format = "{temperatureC}°C {icon}",
        ["format-icons"] = { "", "", "" }
    }

    conf["battery"] = {
        states = { warning = 50, critical = 20 },
        format = "{capacity}% {icon}",
        ["format-charging"] = "{capacity}% 󰂄",
        ["format-plugged"] = "{capacity}% ",
        ["format-alt"] = "{time} {icon}",
        ["format-icons"] = { "", "", "", "", "" },
    }

    local function paFormat(muted, bluetooth)
        local fmt = ""

        if muted then
            fmt = fmt .. "󰝟"
        else
            fmt = fmt .. "{volume}%"
        end

        if not (muted or bluetooth) then
            fmt = fmt .. " {icon}"
        end

        if bluetooth then
            fmt = fmt .. " {icon}"
        end

        fmt = fmt .. " {format_source} "

        return fmt
    end
    conf["pulseaudio"] = {
        format = paFormat(false, false),
        ["format-muted"] = paFormat(true, false),
        ["format-bluetooth"] = paFormat(false, true),
        ["format-bluetooth-muted"] = paFormat(true, true),

        ["format-source"] = "{volume}% ",
        ["format-source-muted"] = "",
        ["format-icons"] = {
            headphone = "",
            ["hands-free"] = "󰋏",
            headset = "󰋎",
            phone = "",
            portable = "",
            car = "",
            default = { "", "", "" },
        },
        ["on-click"] = "pavucontrol",
    }

    conf["network"] = {
        interval = 10,
        format = "{bandwidthDownBytes}  {bandwidthUpBytes}  ",
        ["tooltip-format-ethernet"] = "{ifname} {ipaddr}",
        ["tooltip-format-wifi"] = "{essid} {ipaddr}",
        ["on-click"] = cg.opt.term.exec .. " nmtui",
        ["on-click-right"] = cg.opt.term.exec .. " nmtui",
    }

    return conf
end

return mod
