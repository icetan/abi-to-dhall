{ pkgs ? (import ./pkgs.nix).pkgs
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
    version = "1.26.1";
  in pkgs.buildEnv {
    name = "dhall-haskell-${version}";
    ignoreCollisions = true;
    paths = map (x: dhallHaskellPackage ({ inherit version; } // x)) [
      { subName = null        ; subVersion =  version; sha256 = "09960v0dq2s0qgpzg3pi5sr2c96rs9a5fyl1sdhly9rlkdpjabnm"; }
      { subName = "json"      ; subVersion = "1.4.1" ; sha256 = "00k402x6l010b4v3xf0b1cj3v0gq51f7a7d88crwacjpaabvhf99"; }
    ];
  };

  dhall-prelude = (fetchTarball {
    url = "https://github.com/dhall-lang/dhall-lang/tarball/v10.0.0";
    sha256 = "0gxkr9649jqpykdzqjc98gkwnjry8wp469037brfghyidwsm021m";
  }) + "/Prelude";

  binPaths = with pkgs; lib.makeBinPath [ coreutils gnused dhall-haskell ];

  abi-to-dhall = pkgs.stdenv.mkDerivation {
    name = "abi-to-dhall";
    src = pkgs.lib.sourceByRegex ./. [
      ".*bin.*"
      ".*dhall.*"
    ];
    nativeBuildInputs = with pkgs; [ makeWrapper dhall-haskell ];
    buildPhase = "true";
    installPhase = ''
      mkdir -p $out/dhall/backends

      ln -sf ${dhall-prelude} ./dhall/Prelude
      dhall <<<"./dhall/package.dhall" > $out/dhall/package.dhall
      dhall <<<"./dhall/backends/deploy.dhall" > $out/dhall/backends/deploy.dhall
      dhall <<<"./dhall/backends/json.dhall" > $out/dhall/backends/json.dhall

      cp -r ./bin $out/bin
      wrapProgram $out/bin/abi-to-dhall \
        --set PATH ${binPaths} \
        --set LIB_DIR $out/dhall
    '';
    passthru = {
      buildAbiToDhall = pkgs.callPackage ./dapp-build.nix { inherit dhall-haskell abi-to-dhall; };
    };
  };
in abi-to-dhall
