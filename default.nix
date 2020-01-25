{ pkgs ? import <nixpkgs> {}
}: let
  inherit (pkgs.lib) optionalString makeBinPath;

  binPackage = { name, src, ... }@args: pkgs.stdenv.mkDerivation {
    inherit name src;
    installPhase = ''
      mkdir -p $out/bin
      cp ./bin/* $out/bin
    '';
  } // args;

  dhallHaskellPackage = { version, subName ? null, subVersion, sha256 }: let
    namePart = optionalString (subName != null) "${subName}-";
    name = "dhall-${namePart}bin-${subVersion}";
  in binPackage {
    inherit name;
    src = fetchTarball {
      inherit sha256;
      url = "https://github.com/dhall-lang/dhall-haskell/releases/download/${version}/dhall-${namePart}${subVersion}-${builtins.currentSystem}.tar.bz2";
    };
  };

  dhall-haskell = let
    version = "1.29.0";
  in pkgs.buildEnv {
    name = "dhall-haskell-${version}";
    ignoreCollisions = true;
    paths = map (x: dhallHaskellPackage ({ inherit version; } // x)) [
      { subName = null   ; subVersion =  version ; sha256 = "0nfpppsg2ahdrjkpczifcn5ixc55lc3awxrbggkcd72gf0539abr"; }
      { subName = "json" ; subVersion = "1.6.1"  ; sha256 = "0qddrngfl926dgl29x2xdh32cgx94wkcnsm94kyx87wb4y3cbxga"; }
    ];
  };

  dhall-prelude = (fetchTarball {
    url = "https://github.com/dhall-lang/dhall-lang/tarball/v13.0.0";
    sha256 = "0kg3rzag3irlcldck63rjspls614bc2sbs3zq44h0pzcz9v7z5h9";
  }) + "/Prelude";

  binPaths = with pkgs; lib.makeBinPath [ coreutils gnused gnugrep findutils dhall-haskell ];
  atdBinPaths = with pkgs; lib.makeBinPath [ coreutils gnused bash jq dhall-haskell ];

  abi-to-dhall = pkgs.stdenv.mkDerivation {
    name = "abi-to-dhall";
    src = pkgs.lib.sourceByRegex ./. [
      ".*bin.*"
      ".*dhall.*"
    ];
    nativeBuildInputs = with pkgs; [ makeWrapper dhall-haskell ];
    buildInputs = with pkgs; [ nodejs ];
    buildPhase = "true";
    installPhase = ''
      export XDG_CACHE_HOME="$PWD/.cache"
      mkdir -p $out/dhall/backends "XDG_CACHE_HOME"

      ln -sf ${dhall-prelude} ./dhall/Prelude
      dhall <<<"./dhall/package.dhall" > $out/dhall/package.dhall
      dhall <<<"./dhall/backends/json.dhall" > $out/dhall/backends/json.dhall

      cp -r ./bin $out/bin
      wrapProgram $out/bin/abi-to-dhall \
        --set PATH ${binPaths} \
        --set LIB_DIR $out/dhall \
        --set PRELUDE_PATH ${dhall-prelude}

      wrapProgram $out/bin/atd \
        --prefix PATH : ${atdBinPaths}

      wrapProgram $out/bin/atd-to-seth \
        --prefix PATH : ${with pkgs; lib.makeBinPath [ bash ]}
    '';
    passthru = {
      buildAbiToDhall = pkgs.callPackage ./dapp-build.nix { inherit abi-to-dhall; };
    };
  };
in abi-to-dhall
