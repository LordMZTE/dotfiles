package plugins;

import lua.Table;
import lua.Lua;

class PIndentBlankline implements IPlugin {
    public var name:String = "IndentBlankline";

    public function new() {}

    public function init() {
        Lua.require("ibl")[untyped "setup"](Table.create(null, {
            scope: Table.create(null, {
                include: Table.create(null, {
                    node_type: Table.create(null, {
                        typst: Table.create(["block", "content"], null),
                        zig: Table.create(["block"], null),
                    }),
                }),
            }),
        }));
    }
}
