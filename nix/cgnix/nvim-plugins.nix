{ config, pkgs, lib, stdenv, ... }:
let
  plugin = name: fetchGit { url = "https://git.mzte.de/nvim-plugins/${name}.git"; };

  plugins = {
    # LSP
    lspconfig = plugin "nvim-lspconfig";
    nullls = plugin "null-ls.nvim";
    jdtls = plugin "nvim-jdtls";

    # CMP
    cmp = plugin "nvim-cmp";
    cmp-nvim-lsp = plugin "cmp-nvim-lsp";
    cmp-buffer = plugin "cmp-buffer";
    cmp-path = plugin "cmp-path";
    cmp-cmdline = plugin "cmp-cmdline";
    cmp-luasnip = plugin "cmp_luasnip";
    friendly-snippets = plugin "friendly-snippets";
    luasnip = plugin "LuaSnip";
    cmp-treesitter = plugin "cmp-treesitter";

    # Treesitter
    treesitter = plugin "nvim-treesitter";
    autopairs = plugin "nvim-autopairs";
    ts-autotag = plugin "nvim-ts-autotag";
    ts-context = plugin "nvim-treesitter-context";
    tsn-actions = plugin "ts-node-action";
    ts-playground = plugin "playground";

    # Language Support
    fish = plugin "vim-fish";
    wgsl = plugin "wgsl.vim";
    nu = plugin "nvim-nu";
    crafttweaker = plugin "crafttweaker-vim-highlighting";
    vaxe = plugin "vaxe";

    # Misc
    catppuccin = plugin "catppuccin";
    gitsigns = plugin "gitsigns.nvim";
    lualine = plugin "lualine.nvim";
    tree = plugin "nvim-tree.lua";
    neogit = fetchGit { url = "https://git.mzte.de/nvim-plugins/neogit.git?rev=nightly"; };
    telescope = plugin "telescope.nvim";
    toggleterm = plugin "toggleterm.nvim";
    notify = plugin "nvim-notify";
    dressing = plugin "dressing.nvim"; # TODO: remove once noice gets support for ui.select
    ufo = plugin "nvim-ufo";
    aerial = plugin "aerial.nvim";
    dap = plugin "nvim-dap";
    dapui = plugin "nvim-dap-ui";
    harpoon = plugin "harpoon";
    recorder = plugin "nvim-recorder";
    noice = plugin "noice.nvim";
    lightbulb = plugin "nvim-lightbulb";

    # Libraries
    plenary = plugin "plenary.nvim";
    devicons = plugin "nvim-web-devicons";
    promise-async = plugin "promise-async";
    nio = plugin "nvim-nio";
    nui = plugin "nui.nvim";
  };

  mzte-nv-compiler =
    let
      path = "${builtins.getEnv "HOME"}/.local/bin/mzte-nv-compile";
    in
    if (builtins.pathExists path) then
    # This derivation exists to patch a potentially mismatched dynamic linker.
      stdenv.mkDerivation
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

  config.cgnix.entries.nvim_plugins = pkgs.linkFarm "nvim-plugins"
    (lib.mapAttrsToList
      (name: src: {
        name = name;
        path = stdenv.mkDerivation {
          name = "${name}-compiled";
          inherit src;

          nativeBuildInputs = with pkgs; [ luajit luajitPackages.fennel ];

          buildPhase = ''
            # Compile source with mzte-nv-compile
            ${if mzte-nv-compiler != "" then "${mzte-nv-compiler} ." else ""}
          '';

          installPhase = ''
            mkdir -p "$out"
            mv * .* "$out"
          '';
        };
      })
      config.cgnix.nvim-plugins
    );
}
