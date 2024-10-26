package init;

#if !macro
import ext.mzte_nv.MZTENv;
import ext.vim.Vim;
import lua.Table.AnyTable;

using lua.PairTools;
#end

import haxe.Exception;
import haxe.macro.Context;
import haxe.macro.Expr;

using Lambda;

#if !macro
class Plugins {
    var startupPlugins:Array<IPlugin>;
    var deferredPlugins:Array<IPlugin>;

    var errors:Array<{plug:IPlugin, err:Exception}> = [];

    public function new() {
        regPlugins(["Nu", "Autopairs", "Catppuccin"]);

        this.deferredPlugins = this.deferredPlugins.concat([
            "cmp",
            "dap",
            "devicons",
            "dressing",
            "gitsigns",
            "harpoon",
            "line",
            "lsp-saga",
            "lspconf",
            "lspprogress",
            "luasnip",
            "neogit",
            "nix-update",
            "nullls",
            "nvimtree",
            "recorder",
            "telescope",
            "treesitter",
            "ts-context",
            "tsn-actions",
            "tterm",
            "ufo",
        ].map(n -> (new LuaPlugin(n) : IPlugin)));
    }

    public function init() {
        final pluginpath:String = MZTENv.reg.nvim_plugins;
        if (pluginpath != null) {
            Vim.opt.runtimepath.prepend(pluginpath + "/*");
            Vim.opt.runtimepath.append(pluginpath + ":/*/after");
        }

        if (MZTENv.reg.plugin_load_callbacks == null) {
            MZTENv.reg.plugin_load_callbacks = {};
        }

        for (p in this.startupPlugins) {
            this.loadPlugin(p);
        }
        Vim.schedule(() -> this.loadOneDeferred(0));
    }

    private function loadPlugin(p:IPlugin) {
        try {
            p.init();
        } catch (e) {
            errors.push({plug: p, err: e});
        }
    }

    private function loadOneDeferred(idx:Int) {
        this.loadPlugin(this.deferredPlugins[idx]);

        if (++idx < this.deferredPlugins.length) {
            Vim.schedule(() -> loadOneDeferred(idx));
        } else {
            if (this.errors.length != 0) {
                Vim.notify(
                    this.errors.fold((e, m) -> '$m  - ${e.plug.name}: ${e.err}\n', "Errors while loading plugins:\n"),
                    LogLevel.Error
                );
            }

            cast(MZTENv.reg.plugin_load_callbacks, AnyTable).ipairsEach((_, cb) -> try {
                cb();
            });
        }
    }
}
#end

private macro function regPlugins(names:Array<String>):Expr {
    var startupPlugins = [];
    var deferredPlugins = [];

    for (name in names) {
        final cl = Context.getType('plugins.P${name}');

        switch (cl) {
            case TInst(inst, _):
                final params = inst.get().meta.extract("plugin")[0].params;
                switch (params) {
                    case [{expr: EConst(CInt(prio, _))}, {expr: EConst(CIdent(startup))}]:
                        if (startup == "true") {
                            startupPlugins.push({prio: Std.parseInt(prio), type: inst.get()});
                        } else {
                            deferredPlugins.push({prio: Std.parseInt(prio), type: inst.get()});
                        }
                    default:
                        Context.error("Invalid params", inst.get().meta.extract("plugin")[0].pos);
                }
            default:
        }
    }

    startupPlugins.sort((a, b) -> a.prio - b.prio);
    deferredPlugins.sort((a, b) -> a.prio - b.prio);

    final makeConstructorCall = (p) -> {
        final tpath = {
            params: null,
            sub: null,
            name: p.type.name,
            pack: p.type.pack
        };

        return macro new $tpath();
    };

    final startupPluginExpr = [for (p in startupPlugins) makeConstructorCall(p)];
    final deferredPluginExpr = [for (p in deferredPlugins) makeConstructorCall(p)];

    return macro {
        this.startupPlugins = $a{startupPluginExpr};
        this.deferredPlugins = $a{deferredPluginExpr};
    };
}
