local lfs = require "lfs"
local styles = require "styles"

for f in lfs.dir(luakit.config_dir .. "/styles") do
    if f:match [[.css$]] then
        styles.load_file(luakit.config_dir .. "/styles/" .. f)
    end
end
