package;

import lua.Lua;
import init.Settings;
import init.Plugins;

@:native("_hx_luv")
private class StupidLuvDeadlockHack {
    // Some versions of the Haxe compiler don't implement the `lua-vanilla` flag correctly, still
    // emitting code that starts a libuv loop, which will cause a deadlock in our case.
    // We use this dumb hack to make Haxe's attempt at this ineffective.
    public static var run:Void -> Void;
}

function main() {
    StupidLuvDeadlockHack.run = () -> {};

    Settings.init();
    new Plugins().init();
    Lua.require("maps");
    Lua.require("lsp");
    Lua.require("pipe");
    Lua.require("eval");
}
