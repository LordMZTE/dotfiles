package;

import lua.Lua;
import init.Settings;
import init.Plugins;

function main() {
    Settings.init();
    new Plugins().init();
    Lua.require("maps");
    Lua.require("lsp");
    Lua.require("pipe");
    Lua.require("eval");
}
