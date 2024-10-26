package plugins;

import lua.Lua;

@plugin(50, false)
class PNu implements IPlugin {
	public var name:String = "Nushell";
    public function new() {}

    public function init() {
        final nu:Nu = Lua.require("nu");
        nu.setup({});
    }
}

private extern class Nu {
    @:luaDotMethod
    function setup(opts:{}):Void;
}
