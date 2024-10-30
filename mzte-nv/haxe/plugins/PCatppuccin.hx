package plugins;

import lua.Table;
import ext.vim.Vim;
import lua.Lua;

class PCatppuccin implements IPlugin {
    public var name:String = "Catppuccin";

    public function new() {}

    public function init() {
        final catppuccin = Lua.require("catppuccin");

        catppuccin[untyped "setup"]({
            flavour: "mocha",
            term_colors: true,
            dim_inactive: {enabled: true},
            // Enable only relevant integrations
            default_integrations: false,
            integrations: {
                cmp: true,
                dap: true,
                dap_ui: true,
                gitsigns: true,
                harpoon: true,
                lsp_saga: true,
                markdown: true,
                native_lsp: {
                    enabled: true,
                    virtual_text: Table.fromMap(
                        [
                            for (t in ["errors", "hints", "warnings", "information"])
                                t => Table.fromArray(["italic"])
                        ]
                    ),
                    underlines: Table.fromMap([for (t in ["errors", "hints", "warnings", "information"]) t => Table.fromArray(["italic"])]),
                    inlay_hints: {background: true},
                },
                neogit: true,
                nvimtree: true,
                rainbow_delimiters: true,
                semantic_tokens: true,
                telescope: {enabled: true},
                treesitter: true,
                treesitter_context: true,
            },
        });

        Vim.cmd("colorscheme catppuccin");
    }
}
