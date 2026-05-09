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

.PHONY: full-update
full-update:
	$(MAKE) setup-nix
	systemctl --user restart confgenfs
	sleep 2
	$(MAKE) run-confgen
	$(MAKE) install-scripts setup-nvim-config
