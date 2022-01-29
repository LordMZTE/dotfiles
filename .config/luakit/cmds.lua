local lfs = require "lfs"

require("modes").add_cmds {
    {
        ":update-ab",
        [[Update the adblocker lists]],
        function(w)
            local home = os.getenv "HOME"

            lfs.mkdir(home .. "/.local/share/luakit/adblock/")

            require("downloads").add("https://easylist.to/easylist/easylist.txt", {
                filename = home .. "/.local/share/luakit/adblock/easylist.txt",
            })
        end,
    },
}
