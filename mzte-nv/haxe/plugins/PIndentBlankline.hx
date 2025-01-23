package plugins;

import lua.Table;
import lua.Lua;

class PIndentBlankline implements IPlugin {
	public var name:String = "IndentBlankline";

    public function new() {}

    public function init() {
        Lua.require("ibl")[untyped "setup"](Table.create(null, {}));
    }
}
