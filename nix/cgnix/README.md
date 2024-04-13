# cgnix
This nix module acts as a shim between my confgen environment and nix. It's ultimately one single derivation which is a Lua file that declares paths into the nix store. These can then be used by confgen and thus by my scripts.
