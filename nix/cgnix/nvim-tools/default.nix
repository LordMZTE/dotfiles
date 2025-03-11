{ lib, pkgs, system, config, ... }:
let
  flakePkg = ref: (builtins.getFlake ref).packages.${system}.default;
  default-packages = with pkgs; [
    # MISSING: racket_langserver
    # Language Servers
    (pkgs.linkFarm "clang-nvim" (map
      (bin: { name = "bin/${bin}"; path = "${clang-tools}/bin/${bin}"; })
      [ "clangd" "clang-format" ])) # Don't include everything from clang-tools
    (pkgs.stdenv.mkDerivation {
      name = "glsl-analyzer";
      src = pkgs.fetchFromGitHub {
        owner = "nolanderc";
        repo = "glsl_analyzer";
        rev = "5b9848b2dd563170cd702c41443659d6b3cb11de";
        leaveDotGit = true;
        hash = "sha256-J7drPaIOIyFr6ib1GrhqD80fTRz7y3ewTG9lFaNAO5s=";
      };

      dontConfigure = true;

      nativeBuildInputs = with pkgs; [ zig_0_13.hook git ];
    })
    (flakePkg "git+https://git.mzte.de/LordMZTE/haxe-language-server.git")
    config.output.packages.jdtls-wrapped
    (
      pkgs.stdenvNoCC.mkDerivation rec {
        pname = "ltex-ls-plus";
        version = "18.5.0-alpha.nightly.2025-03-09";
        src = fetchurl {
          # Nightly releases are not persistent upstream,
          # so they're (manually) reuploaded to MZTE Git.
          url =
            "https://git.mzte.de/api/packages/LordMZTE/generic/${pname}/${version}/${pname}-${version}.tar.gz";
          sha256 = "sha256-qb+W5foyjkBDpMMVuKO8M/vy/oA5EoKoMdpcSyGX+z8=";
        };

        preferLocalBuild = true;

        nativeBuildInputs = [ makeBinaryWrapper ];

        installPhase = ''
          runHook preInstall

          mkdir -p $out
          cp -rfv bin/ lib/ $out
          rm -fv $out/bin/.lsp-cli.json $out/bin/*.bat
          for file in $out/bin/{ltex-ls-plus,ltex-cli-plus}; do
            wrapProgram $file --set JAVA_HOME "${jre_headless}"
          done

          runHook postInstall
        '';
      }
    )
    lua-language-server
    (flakePkg "github:oxalica/nil")
    openscad-lsp
    rust-analyzer
    taplo
    tinymist
    vscode-langservers-extracted # cssls, eslint, html, jsonls
    (flakePkg "github:zigtools/zls/336f468c1fddbb8b7356946f4f2ee69434edfaad")
    #zls

    # Formatters
    (pkgs.linkFarm "prettier" [{ name = "bin/prettier"; path = "${nodePackages.prettier}/bin/prettier"; }]) # needed due to symlink shenanigans
    fnlfmt
    nixpkgs-fmt
    rustfmt
    shfmt
    stylua

    # Misc
    html-tidy
    nix-update # nix-update.nvim
    nurl # nix-update.nvim
    tree-sitter
  ];
in
{
  options.cgnix.nvim-tools = lib.mkOption {
    default = default-packages;
  };

  config.cgnix.entries.nvim_tools = pkgs.symlinkJoin {
    name = "nvim-tools";
    paths = config.cgnix.nvim-tools;
  };
}
