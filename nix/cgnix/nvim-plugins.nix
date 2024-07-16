{ config, pkgs, lib, stdenvNoCC, ... }:
let
  plugin = name: fetchGit { url = "https://git.mzte.de/nvim-plugins/${name}.git"; };

  plugins = {
    # LSP
    "20-lspconfig" = plugin "nvim-lspconfig";
    "20-nullls" = plugin "null-ls.nvim";
    "20-jdtls" = plugin "nvim-jdtls";
    "20-lsp-saga" = plugin "lspsaga.nvim";

    # CMP
    "45-cmp" = plugin "nvim-cmp";
    "50-cmp-nvim-lsp" = plugin "cmp-nvim-lsp";
    "50-cmp-buffer" = plugin "cmp-buffer";
    "50-cmp-path" = plugin "cmp-path";
    "50-cmp-cmdline" = plugin "cmp-cmdline";
    "50-cmp-luasnip" = plugin "cmp_luasnip";
    "50-friendly-snippets" = plugin "friendly-snippets";
    "50-luasnip" = plugin "LuaSnip";
    "50-cmp-treesitter" = plugin "cmp-treesitter";

    # Treesitter
    "30-treesitter" = plugin "nvim-treesitter";
    "30-autopairs" = plugin "nvim-autopairs";
    "30-ts-autotag" = plugin "nvim-ts-autotag";
    "30-ts-context" = plugin "nvim-treesitter-context";
    "30-tsn-actions" = plugin "ts-node-action";
    "30-ts-playground" = plugin "playground";

    # Language Support
    "30-fish" = plugin "vim-fish";
    "30-wgsl" = plugin "wgsl.vim";
    "30-nu" = plugin "nvim-nu";
    "30-crafttweaker" = plugin "crafttweaker-vim-highlighting";
    "30-vaxe" = plugin "vaxe";
    "30-nix-update" = plugin "nix-update.nvim";

    # Misc
    "50-catppuccin" = plugin "catppuccin";
    "50-gitsigns" = plugin "gitsigns.nvim";
    "50-lualine" = plugin "lualine.nvim";
    "50-tree" = plugin "nvim-tree.lua";
    "50-neogit" = fetchGit { url = "https://git.mzte.de/nvim-plugins/neogit.git?rev=nightly"; };
    "50-telescope" = plugin "telescope.nvim";
    "50-toggleterm" = plugin "toggleterm.nvim";
    "50-dressing" = plugin "dressing.nvim";
    "50-ufo" = plugin "nvim-ufo";
    "50-dap" = plugin "nvim-dap";
    "50-dapui" = plugin "nvim-dap-ui";
    "50-harpoon" = plugin "harpoon";
    "50-recorder" = plugin "nvim-recorder";
    "50-lsp-progress" = plugin "lsp-progress.nvim";

    # Libraries
    "10-plenary" = plugin "plenary.nvim";
    "10-devicons" = plugin "nvim-web-devicons";
    "10-promise-async" = plugin "promise-async";
    "10-nio" = plugin "nvim-nio";
    "10-nui" = plugin "nui.nvim";
  };

  mzte-nv-compiler =
    let
      path = "${builtins.getEnv "HOME"}/.local/bin/mzte-nv-compile";
    in
    if (builtins.pathExists path) then
    # This derivation exists to patch a potentially mismatched dynamic linker.
      stdenvNoCC.mkDerivation
        {
          name = "mzte-nv-compiler-patched";
          nativeBuildInputs = [ pkgs.autoPatchelfHook ];
          buildInputs = with pkgs; [ luajit ];
          dontUnpack = true;
          buildPhase = ''
            cp ${/. + path} $out
          '';
        } else "";
in
{
  options.cgnix.nvim-plugins = lib.mkOption { };
  config.cgnix.nvim-plugins = plugins;

  config.cgnix.entries.nvim_plugins = stdenvNoCC.mkDerivation {
    name = "nvim-plugins";

    nativeBuildInputs = with pkgs; [ luajit luajitPackages.fennel ];

    unpackPhase = ''
      # Copy plugins sources here
      mkdir plugins
      ${builtins.concatStringsSep "\n" (lib.mapAttrsToList
                                        (name: src: "cp -r ${src} plugins/${name}")
                                        config.cgnix.nvim-plugins)}
      chmod -R +rw plugins
    '';

    buildPhase = ''
      # Compile
      ${if mzte-nv-compiler != "" then "${mzte-nv-compiler} plugins" else ""}
    '';

    installPhase = ''
      mv plugins "$out"
    '';
  };
}
