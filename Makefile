NIX = nom

.PHONY: install-scripts
install-scripts:
	zig build -Doptimize=ReleaseFast -p ~/.local

.PHONY: setup-nix
setup-nix:
	$(NIX) build .#cgnix --impure --out-link nix/cgnix/nix.lua

.PHONY: setup-nvim-config
setup-nvim-config:
	$(MAKE) -C mzte-nv

.PHONY: run-confgen
run-confgen:
	confgen confgen.lua cgout
