#!/bin/bash
{
    echo -n '(0'
    find "${1-.}" -type f | while read -r f; do
        echo -n +
        ffprobe -v quiet -of csv=p=0 -show_entries format=duration "$f" | tr -d '\n'
    done
    echo -n ')s'
} | qalc
