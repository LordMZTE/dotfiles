#!/bin/sh

set -e
# viuer doesn't like xterm-kitty
export TERM=xterm-256color

mime=$(file -b --mime-type "$1")

case $mime in
image/*) viu $1 ;;
*) bat $1 --color=always ;;
esac
