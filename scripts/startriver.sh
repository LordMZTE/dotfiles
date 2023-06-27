#!/bin/sh

# keyboard config
export XKB_DEFAULT_OPTIONS="caps:swapescape"
export XKB_DEFAULT_LAYOUT="de"

# other stuff
export QT_QPA_PLATFORM="wayland"

# this is necessary for tray icons
export XDG_CURRENT_DESKTOP="river"

exec river
