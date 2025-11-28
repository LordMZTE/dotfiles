package init;

import plugins.*;
import haxe.Exception;
import ext.mzte_nv.MZTENv;
import ext.vim.Vim;
import lua.Table.AnyTable;

using lua.PairTools;
using Lambda;

class Plugins {
    var startupPlugins:Array<IPlugin>;
    var deferredPlugins:Array<IPlugin>;

    var errors:Array<{plug:IPlugin, err:Exception}> = [];

    public function new() {
        this.startupPlugins = [
            new PCatppuccin(), // avoid flicker of default theme
            new LuaPlugin("inlay-hint"), // same reason as lspconf
            new LuaPlugin("lspconf"), // loaded on startup for LSP in files opened in command
            new LuaPlugin("treesitter"), // enable TS in files opened in command
        ];
        this.deferredPlugins = [cast(new PNu(), IPlugin)].concat([
            "cmp",
            "confgen",
            "dap",
            "devicons",
            "dressing",
            "gitsigns",
            "lspprogress",
            "line",
            "lsp-saga",
            "luasnip",
            "neogit",
            "nix-update",
            "nullls",
            "nvimtree",
            "recorder",
            "telescope",
            "tterm",
            "overseer",
            "ufo",
            "mini",
        ].map(n -> (new LuaPlugin(n) : IPlugin)));
    }

    public function init() {
        final pluginpath:String = MZTENv.reg.nvim_plugins;
        if (pluginpath != null) {
            Vim.opt.runtimepath.prepend(pluginpath + "/*");
            Vim.opt.runtimepath.append(pluginpath + "/*/after");
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
