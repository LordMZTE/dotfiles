package plugins;

import ext.vim.Vim;
import ext.mzte_nv.MZTENv;
import lua.Lua;
import lua.Table;

using StaticTools;
using StringTools;
using lua.NativeStringTools;

class PTSNActions implements IPlugin {
    public var name:String = "Tree-Sitter Node Actions";
    public var zig_padding:Table<String, String> = [
        ")" => " %s",
        "]" => " %s",
        "}" => " %s",
        "{" => "%s ",
        "," => "%s ",
        "=" => " %s ",
        "+" => " %s ",
        "-" => " %s ",
        "*" => " %s ",
        "/" => " %s ",
        "**" => " %s ",
        "++" => " %s ",
    ].toTable();

    private var tsna_helpers:Dynamic;

    public function new() {}

    public function init() {
        final tsna = Lua.require("ts-node-action");
        final tsna_actions = Lua.require("ts-node-action.actions");
        this.tsna_helpers = Lua.require("ts-node-action.helpers");
        final nullls = Lua.require("null-ls");

        final zig_multiline_action = tsna_actions[untyped "toggle_multiline"](this.zig_padding);
        final toggle_int_action = Table.create([
            Table.create(
                [(node) -> MZTENv.tsn_actions.intToggle(this.tsna_helpers[untyped "node_text"](node))],
                {name: "Toggle Dec/Hex"}
            )
        ]);

        tsna[untyped "setup"]({
            zig: {
                call_expression: zig_multiline_action,
                struct_declaration: zig_multiline_action,
                initializer_list: zig_multiline_action,
                variable_declaration: Table.create([
                    Table.create(
                        [(node) -> MZTENv.tsn_actions.zigToggleMutability(this.tsna_helpers[untyped "node_text"](node))],
                        {
                            name: "Toggle Mutability",
                        }
                    )
                ]),
                integer: toggle_int_action,
            },
            markdown: [for (i in 1...7) 'atx_h${i}_marker' => {
                final next = i == 6 ? 1 : i + 1;
                Table.create([_ -> NativeStringTools.rep("#", next)], {
                    name: 'Convert to H$next'
                });
            }].toTable(),
            java: {
                hex_integer_literal: Table.create(
                    [
                        Table.create(
                            [(node) -> MZTENv.tsn_actions.intToDec(this.tsna_helpers[untyped "node_text"](node))],
                            {
                                name: "Convert to Decimal",
                            }
                        )
                    ]
                ),
                decimal_integer_literal: Table.create([Table.create([(node) ->
                            MZTENv.tsn_actions.intToHex(this.tsna_helpers[untyped "node_text"](node))], {
                    name: "Convert to Hexadecimal",
                })]),
            },
            c: {
                number_literal: toggle_int_action,
            },
            cpp: {
                number_literal: toggle_int_action,
            },
            lua: {
                number: toggle_int_action,
            },
            fennel: {
                number: toggle_int_action,
            },
            typst: {
                math: Table.create([Table.create([toggleTypstMath], {name: "Expand/Contract math"})])
            },
        });

        nullls[untyped "register"]({
            name: "TSNA",
            method: Table.create([(cast nullls : Dynamic).methods.CODE_ACTION]),
            filetypes: Table.create(["_all"]),
            generator: {fn: tsna[untyped "available_actions"]},
        });

        Vim.keymap.set("n", "U", tsna[untyped "node_action"], MZTENv.utils.map_opt);
    }

    private function toggleTypstMath(node:Dynamic):String {
        final text:String = this.tsna_helpers[untyped "node_text"](node);

        final sub1 = text.gsub("^%$%s+(.*)%s+%$$", "%$%1%$");
        if (sub1 == text) {
            // This assignment is necessary because haxe doesn't realize that gsub is a multireturn.
            // TODO: open issue about this
            final sub2 = text.gsub("^%$", "%$ ").gsub("%$$", " %$");
            return sub2;
        } else return sub1;
    }
}
