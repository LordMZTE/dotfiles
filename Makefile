# this includes some scripts to set up the environment quickly

RUST_PROGRAMS=\
	alacritty \
	bat \
	cargo-edit \
	gitui \
	lsd \
	mask \
	miniserve \
	onefetch \
	ripgrep \
	starship \
	tiny \
	tokei \
	zoxide

.PHONY: install_rust_programs
.PHONY: install_rustup

install_rustup:
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

install_rust_programs:
	cargo install $(RUST_PROGRAMS)
