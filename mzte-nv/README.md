# mzte-nv

This directory contains my neovim configuration.
It consits of:
- The Zig native module, loaded using LuaJIT C library support in `src`. This contains code for
  adjusting nvim's own settings as well as various utilities. It also has various options
  originating from Confgen(FS) compiled into it which are exposed via a Lua API to be used by
  other parts of the configuration.

- The main entrypoint written in Haxe in `haxe`. This is compiled to a `hx.lua` file, which is
  invoked by a shim inside `conf` after the Zig module has been preloaded.
  It uses the Zig module's compiled-in plugin path (usually in the Nix store) to load
  plugins. It also includes some Plugin configurations and other code.

- Additional Lua files written in Fennel or Lua in `conf` as well as other configuration files.
  These are compiled and then dumped into the config directory directly. Most plugin configurations
  currently live here.

## a rough overview of how to install this
First, you must build cgnix using `./setup.rkt setup-nix`. This will build a Nix package including
options included by Confgen, which depends on the plugin bundle we will compile into mzte-nv later.

Then, you must somehow generate a Confgen `opts.json` file. You could do this by using `confgen -j
confgen.lua`, or you can mount ConfgenFS somewhere. The path of this JSON file can then be specified
using the `CGOPTS` env var, which defaults to `./cgout/_cgfs/opts.json`, which you will get if you
just invoke `./setup.rkt run-confgen`.

Then, you should be able to build and install mzte-nv with `./setup.rkt setup-nvim-config`
