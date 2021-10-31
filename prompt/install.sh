#!/bin/sh
# builds and installs the prompt to ~/.local/bin
set -e

RUSTFLAGS="-C target-cpu=native" cargo build --release
strip target/release/prompt
cp target/release/prompt ~/.local/bin
