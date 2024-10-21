#!/usr/bin/env bash
tmpf=$(mktemp --suffix=.pdf)
trap 'kill $(jobs -p); rm "$tmpf"' EXIT

typst watch "$1" "$tmpf" "${@:2}" &

while [ ! -f "$tmpf" ]; do sleep 1; done

zathura "$tmpf"
