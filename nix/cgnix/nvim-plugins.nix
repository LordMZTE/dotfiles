{ config, pkgs, lib, stdenv, stdenvNoCC, ... }:
let
  plugin = name: fetchGit { url = "https://git.mzte.de/nvim-plugins/${name}.git"; };

  plugins = {
    # LSP
    "20-lspconfig" = plugin "nvim-lspconfig";
    "20-nonels" = plugin "none-ls.nvim";
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
    "50-cmp-latex-symbols" = plugin "nvim-cmp-lua-latex-symbols";
    "50-colorful-menu" = plugin "colorful-menu.nvim";

    # Treesitter
    "30-treesitter" = plugin "nvim-treesitter";
    "30-ts-autotag" = plugin "nvim-ts-autotag";
    "30-ts-context" = plugin "nvim-treesitter-context";
    "30-tsn-actions" = plugin "ts-node-action";
    "30-ts-playground" = plugin "playground";
    "30-ts-textobjects" = plugin "nvim-treesitter-textobjects";

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
    "50-neogit" = plugin "neogit";
    "50-telescope" = plugin "telescope.nvim";
    "50-toggleterm" = plugin "toggleterm.nvim";
    "50-dressing" = plugin "dressing.nvim";
    "50-ufo" = plugin "nvim-ufo";
    "50-dap" = plugin "nvim-dap";
    "50-dapui" = plugin "nvim-dap-ui";
    "50-recorder" = plugin "nvim-recorder";
    "50-ibl" = plugin "indent-blankline.nvim";
    "50-lsp-progress" = plugin "lsp-progress.nvim";
    "50-mini" = plugin "mini.nvim";

    # Libraries
    "10-plenary" = plugin "plenary.nvim";
    "10-devicons" = plugin "nvim-web-devicons";
    "10-promise-async" = plugin "promise-async";
    "10-nio" = plugin "nvim-nio";
    "10-nui" = plugin "nui.nvim";
  };

  mzte-nv-compiler = stdenv.mkDerivation {
    name = "mzte-nv-compiler";
    src = lib.fileset.toSource {
      root = ../..;
      fileset = lib.fileset.unions [
        ../../lib/common-zig
        ../../mzte-nv/src
        ../../mzte-nv/build.zig
        ../../mzte-nv/build.zig.zon
      ];
    };
    patchPhase = "cd mzte-nv";

    nativeBuildInputs = with pkgs; [ zig_0_15.hook makeBinaryWrapper ];
    buildInputs = with pkgs; [ pkg-config luajit ];

    zigBuildFlags = [ "-Dcompiler-only" ];

    postInstall = ''
      wrapProgram $out/bin/mzte-nv-compile \
        --set MZTE_NV_FENNEL "${pkgs.luajitPackages.fennel}/share/lua/5.1/fennel.lua"
    '';
  };
in
{
  options.cgnix.nvim-plugins = lib.mkOption { };
  config.cgnix.nvim-plugins = plugins;

  config.cgnix.entries.nvim_plugins = stdenvNoCC.mkDerivation {
    name = "nvim-plugins";

    preferLocalBuild = true;

    unpackPhase = ''
      # Copy plugins sources here
      mkdir plugins
      ${builtins.concatStringsSep "\n" (lib.mapAttrsToList
                                        (name: src: "cp -r ${src} plugins/${name}")
                                        config.cgnix.nvim-plugins)}
      chmod -R +rw plugins
    '';

    buildPhase = ''
      # Generate helptags
      for doc in plugins/*/doc; do
        echo "generating helptags @ $doc"
        ${pkgs.neovim-unwrapped}/bin/nvim -n -Es -u NONE -i NONE -c "helptags $doc" +quit!
      done

      # Compile
      ${mzte-nv-compiler}/bin/mzte-nv-compile plugins
    '';

    installPhase = ''
      mv plugins "$out"
    '';
  };
}
