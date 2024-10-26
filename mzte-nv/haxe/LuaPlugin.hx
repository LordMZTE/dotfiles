package;

import lua.Lua;

class LuaPlugin implements IPlugin {
	public var name:String;

    public function new(id:String) {
        this.name = id;
    }

	public function init() {
        Lua.require("pluginconf.p-" + this.name);
    }
}
