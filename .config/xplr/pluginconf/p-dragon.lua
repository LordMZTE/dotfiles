require("dragon").setup {
    -- Seems like people are unsure of what the canonical binary name for dragon is. The default is
    -- "dragon", but it seems to be "dragon-drop" on NixOS and I recall it being that on Arch too.
    bin = "dragon-drop",
}
