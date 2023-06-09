#!/bin/sh

# keyboard config
export XKB_DEFAULT_OPTIONS="caps:swapescape"
export XKB_DEFAULT_LAYOUT="de"

# other stuff
export QT_QPA_PLATFORM="wayland"

# this is necessary for tray icons
export XDG_CURRENT_DESKTOP="river"

# theming
export GTK_THEME=Catppuccin-Mocha-Standard-Red-Dark
export QT_QPA_PLATFORMTHEME=gtk2
export _JAVA_OPTIONS='-Dawt.useSystemAAFontSettings=on -Dswing.aatext=true -Dswing.defaultlaf=com.sun.java.swing.plaf.gtk.GTKLookAndFeel -Dswing.crossplatformlaf=com.sun.java.swing.plaf.gtk.GTKLookAndFeel'

exec river
