if exists("g:GtkGuiLoaded")
    call rpcnotify(1, 'Gui', 'Font', 'Iosevka 12')
else
    GuiFont! Iosevka:h12
endif

