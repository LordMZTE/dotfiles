#!/bin/sh
__usage="
USAGE:
    $0 <java-name> <command...>

ARGS:
    <java-name> the jvm to use
    <command...> the command to run
"

if [ 3 -gt $# ]; then
    echo -e "$__usage"
else
    export PATH="/usr/lib/jvm/$1/bin:$PATH"
    ${@:2}
fi

