# Basically an alias except it runs neovide as a job instead of completely detaching.
function nvide --wraps neovide
    neovide --no-fork $argv &
end
