package plugins;

import lua.Lua;

class PAutopairs implements IPlugin {
    public var name:String = "Autopairs";

    public function new() {}

    public function init() {
        Lua.require("nvim-autopairs")[untyped "setup"]({
            check_ts: true,
            fast_wrap: {
                map: "<M-e>",
                cursor_pos_before: false,
            },
        });

        Lua.require("cmp").event.on(
            "confirm_done",
            Lua.require("nvim-autopairs.completion.cmp")[untyped "on_confirm_done"]({map_char: {tex: ""}})
        );
    }
}
