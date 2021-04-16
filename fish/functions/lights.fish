function lights
    set lights (huectl light get | sed '/\"id\"/!d; s/.* \"//; s/\".*//')

    for l in $lights
        huectl light set $l $argv
    end
end

