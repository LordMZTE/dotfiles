# My dotfiles

I'm actually making the claim now that this repo might just be the most hilariously complicated configuration in existance.

This is my system configuration, built mostly for arch & SystemD based linuxes.

Here's some useful facts:

- Config files are generated using confgen, my config file template engine. Options that can be changed are in cg_opts.lua. This makes for a centralized place for common options like fonts. This allows for complete deduplication.
- The neovim config is written in part Zig (yes, really) and part fennel. Use `./setup.rkt setup-nvim-config` to build and install it.
- Lua/Fennel files in the nvim config are compiled to lua bytecode.
- Theres a `setup.rkt` racket script with convenient functions such as installing scripts, building the config and setting up the neovim configuration.
- I have a lot of scripts, written in Zig, Racket and some in shell.
