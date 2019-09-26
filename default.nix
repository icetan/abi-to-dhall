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

  binPaths = with pkgs; makeBinPath [ coreutils gnused dhall-haskell ];

in pkgs.stdenv.mkDerivation {
  name = "abi-to-dhall";
  src = ./.;
  nativeBuildInputs = with pkgs; [ makeWrapper dhall-haskell ];
  buildPhase = "true";
  installPhase = ''
    mkdir -p $out/{bin,lib/backends}

    ln -s ${dhall-prelude} ./Prelude
    dhall <<<"./abiGenerator.dhall" > $out/lib/abiGenerator.dhall
    dhall <<<"./abiSchema.dhall" > $out/lib/abiSchema.dhall
    dhall <<<"./typesGenerator.dhall" > $out/lib/typesGenerator.dhall
    dhall <<<"./lib.dhall" > $out/lib/lib.dhall
    dhall <<<"./backends/deploy" > $out/lib/backends/deploy

    cp ./abi-to-dhall $out/bin/abi-to-dhall
    wrapProgram $out/bin/abi-to-dhall \
      --set PATH ${binPaths} \
      --set LIB_DIR $out/lib
  '';
}
