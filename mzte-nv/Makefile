.PHONY: build clean-dir zig-mod haxe conf-files

build: haxe conf-files zig-mod
	mzte-nv-compile ~/.config/nvim

clean-dir:
	rm -rf ~/.config/nvim

zig-mod:
	zig build -Doptimize=ReleaseSafe -p ~/.local

haxe: clean-dir
	haxe -cp haxe --main Main -D lua-vanilla -D dce=full -D lua-jit --lua ~/.config/nvim/lua/hx.lua

conf-files: clean-dir
	cp -r conf ~/.config/nvim/
