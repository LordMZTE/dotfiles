{ lib, pkgs, stdenvNoCC, ... }:
let
  mkHaxelib = { libname, version, src }: stdenvNoCC.mkDerivation {
    name = "${libname}-${version}";
    inherit src;

    installPhase = ''
      runHook preInstall
      ver="${lib.replaceStrings ["."] [","] version}"
      mkdir $out
      if [ $(ls $src | wc -l) == 1 ]; then
        cp -r $src/* $out/$ver
      else
        cp -r $src $out/$ver
      fi
      echo ${version} > $out/.current
      runHook postInstall
    '';
  };

  fetchHaxelib = { libname, version, hash ? "" }: mkHaxelib {
    inherit libname version;
    src = pkgs.fetchzip {
      url = "http://lib.haxe.org/files/3.0/${lib.replaceStrings ["."] [","] "${libname}-${version}"}.zip";
      stripRoot = false;
      inherit hash;
    };
  };

  deps = pkgs.linkFarm "haxelib-deps" [
    # Direct deps
    {
      name = "hxnodejs";
      path = mkHaxelib {
        libname = "hxnodejs";
        version = "git";
        src = pkgs.fetchFromGitHub {
          owner = "HaxeFoundation";
          repo = "hxnodejs";
          rev = "504066dc1ba5ad543afa5f6c3ea019f06136a82b";
          hash = "sha256-/QTwm7oKdPnTYFMaEZ6q3FwqBBu++rcf0SbaKJ6KjuA=";
        };
      };
    }
    {
      name = "hxparse";
      path = mkHaxelib {
        libname = "hxparse";
        version = "git";
        src = pkgs.fetchFromGitHub {
          owner = "simn";
          repo = "hxparse";
          rev = "876070ec62a4869de60081f87763e23457a3bda8";
          hash = "sha256-uIsF0oAXVY+MrJDXlsYobD1pwq3HsTowK6NMMRgD2fg=";
        };
      };
    }
    {
      name = "haxeparser";
      path = mkHaxelib {
        libname = "haxeparser";
        version = "git";
        src = pkgs.fetchFromGitHub {
          owner = "HaxeCheckstyle";
          repo = "haxeparser";
          rev = "7e98c9aef901b8e26541cf3f8a6e1da0385b237a";
          hash = "sha256-T61tEtdLBe16+XPXnmxQkoqpZa2FhAohQBMwHkMiFr0=";
        };
      };
    }
    {
      name = "tokentree";
      path = fetchHaxelib {
        libname = "tokentree";
        version = "1.2.10";
        hash = "sha256-f3OpLPDcigsTB7dpwV9PTUBuTxprdc6aEPEc81OfO9o=";
      };
    }
    {
      name = "formatter";
      path = fetchHaxelib {
        libname = "formatter";
        version = "1.15.0";
        hash = "sha256-cCDuG5YbU+07BrWVJIK1wjsEgvde5lqIOLLZMniTPfc=";
      };
    }
    {
      name = "rename";
      path = fetchHaxelib {
        libname = "rename";
        version = "2.2.2";
        hash = "sha256-pyQhG+oFeb7XKV1I4CEASedi0NiFZuHV5/OBNLYZRIo=";
      };
    }
    {
      name = "json2object";
      path = mkHaxelib {
        libname = "json2object";
        version = "git";
        src = pkgs.fetchFromGitHub {
          owner = "elnabo";
          repo = "json2object";
          rev = "429986134031cbb1980f09d0d3d642b4b4cbcd6a";
          hash = "sha256-UwPbDL9pICmShhRik3fGCDJrvj0oUuGgVziPMZW4DHY=";
        };
      };
    }
    {
      name = "language-server-protocol";
      path = mkHaxelib {
        libname = "language-server-protocol";
        version = "git";
        src = pkgs.fetchFromGitHub {
          owner = "vshaxe";
          repo = "language-server-protocol-haxe";
          rev = "a6baa2ddcd792e99b19398048ef95aa00f0aa1f6";
          hash = "sha256-CAAn6zeR3oV16fPQerZFgZ0dZaZj5MzbHvhtwhEZ0Ro=";
        };
      };
    }
    {
      name = "vscode-json-rpc";
      path = mkHaxelib {
        libname = "vscode-json-rpc";
        version = "git";
        src = pkgs.fetchFromGitHub {
          owner = "vshaxe";
          repo = "vscode-json-rpc";
          rev = "0160f06bc9df1dd0547f2edf23753540db74ed5b";
          hash = "sha256-dwd2Ml9kORtkAs0P4B9qC+HTI2JOaLRzxpppeGbnlos=";
        };
      };
    }
    {
      name = "uglifyjs";
      path = fetchHaxelib {
        libname = "uglifyjs";
        version = "1.0.0";
        hash = "sha256-1dR6BzftIXe68U8kFi2A2mssOEcCOkrervmsnxwwpFw=";
      };
    }
    {
      name = "safety";
      path = fetchHaxelib {
        libname = "safety";
        version = "1.1.2";
        hash = "sha256-fq+W8Or6raW00vsRQ1nbjs4IPou9MV536Yj+uk9VHyU=";
      };
    }

    # Indirect deps
    {
      name = "hxjsonast";
      path = fetchHaxelib {
        libname = "hxjsonast";
        version = "1.1.0";
        hash = "sha256-5Kbq/hDKypx29omnU8bFfd634KqBVYybEmUZh13qjYc=";
      };
    }
    {
      name = "test-adapter";
      path = fetchHaxelib {
        libname = "test-adapter";
        version = "2.0.4";
        hash = "sha256-OAw/JEL26LZqlY9n2OeeVvp/i4Ts5x3WyoPFYMUBg8k=";
      };
    }
    {
      name = "utest";
      path = mkHaxelib {
        libname = "utest";
        version = "git";
        src = pkgs.fetchFromGitHub {
          owner = "haxe-utest";
          repo = "utest";
          rev = "a94f8812e8786f2b5fec52ce9f26927591d26327";
          hash = "sha256-cf7688QxtuQGHvTsG/eJ2PNOVUrcNG/G5ZaysDH5two=";
        };
      };
    }
  ];
in
pkgs.stdenvNoCC.mkDerivation {
  name = "haxe-language-server";
  src = pkgs.fetchFromGitHub {
    owner = "klabz";
    repo = "haxe-languageserver";
    rev = "012951e82f023bc1f662a4b7520c3a39817988ef";
    hash = "sha256-rKzyeLbXNBL3wGXYtb3n9YNU0Qwm1Tsl2XPJYXMEjAo=";
  };

  nativeBuildInputs = with pkgs; [ haxe nodePackages.uglify-js ];

  configurePhase = ''
    runHook preConfigure
    export HOME=/build
    echo '${deps}' > /build/.haxelib
    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild
    haxe build.hxml
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    echo '#!${pkgs.nodejs}/bin/node' > $out/bin/haxe-language-server
    cat bin/server.js >> $out/bin/haxe-language-server
    chmod +x $out/bin/haxe-language-server
    runHook postInstall
  '';
}
