#!/bin/sh
set -ex

# This is a small wrapper script that uses reflector to update the pacman mirrors
# using the fastest servers of a given country.

reflector \
    --country "$1" \
    --fastest 10 \
    --save /etc/pacman.d/mirrorlist
