#!/usr/bin/env bash
tmpf=$(mktemp --suffix=.pdf)
trap 'kill $(jobs -p); rm "$tmpf"' EXIT

typst watch "$1" "$tmpf" "${@:2}" &

 # Without this, zathura may try to open a half-written file. This is a hack, but I don't know of a
 # better approach.
sleep 1

zathura "$tmpf"
