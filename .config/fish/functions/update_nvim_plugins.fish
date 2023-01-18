# This function updates neovim plugins.
# This is more or less just a workaround until packer can support my exotic setup.

function update_nvim_plugins
    set prevdir (pwd)

    set packdir ~/.local/share/nvim/site/pack/packer/
    cd $packdir

    for d in (fd '\.git$' --hidden --type directory)
        cd $d/..
        # reset is needed because of compiled lua files
        git reset --hard HEAD
        git pull
        cd $packdir
    end

    cd $prevdir
end
