{ pkgs ? import <nixpkgs> {} }: let
  version = "1.0.0";

  inherit (pkgs) runCommand makeWrapper;
  inherit (pkgs.lib) optionalString makeBinPath;

  binPackage = { name, src, ... }@args: pkgs.stdenv.mkDerivation {
    inherit name src;
    installPhase = ''
      mkdir -p $out/bin
      [ ! -d ./bin ] || cd ./bin
      cp -t $out/bin ./*
    '';
  } // args;

  dhallHaskellPackage = { version, subName ? null, subVersion, sha256 }: let
    system = if pkgs.stdenv.isDarwin then "x86_64-macos" else builtins.currentSystem;
    namePart = optionalString (subName != null) "${subName}-";
    name = "dhall-${namePart}bin-${subVersion}";
  in binPackage {
    inherit name;
    src = fetchTarball {
      sha256 = sha256."${system}";
      url = "https://github.com/dhall-lang/dhall-haskell/releases/download/${version}/dhall-${namePart}${subVersion}-${system}.tar.bz2";
    };
  };

  dhall-haskell = let
    version = "1.29.0";
  in pkgs.buildEnv {
    name = "dhall-haskell-${version}";
    ignoreCollisions = true;
    paths = map (x: dhallHaskellPackage ({ inherit version; } // x)) [
      { subName = null;
        subVersion = version;
        sha256 = {
          x86_64-linux = "0nfpppsg2ahdrjkpczifcn5ixc55lc3awxrbggkcd72gf0539abr";
          x86_64-macos = "0impdrphm7wsm5i17dwyq12i1nrirq78n20kbjz68ahyrf1b8ld7";
        };
      }
      { subName = "json";
        subVersion = "1.6.1";
        sha256 = {
          x86_64-linux = "0qddrngfl926dgl29x2xdh32cgx94wkcnsm94kyx87wb4y3cbxga";
          x86_64-macos = "061yxgxh376qf5mha5glzayhjs6qgw3vv6acxzh3zaiz424p1bvz";
        };
      }
    ];
  };

  dhall-prelude = (fetchTarball {
    url = "https://github.com/dhall-lang/dhall-lang/tarball/v13.0.0";
    sha256 = "0kg3rzag3irlcldck63rjspls614bc2sbs3zq44h0pzcz9v7z5h9";
  }) + "/Prelude";

  binPaths = with pkgs; makeBinPath [ coreutils gnused findutils dhall-haskell ];
  atdBinPaths = with pkgs; makeBinPath [ coreutils gnused findutils bash jq dhall-haskell ];

  atd-to-seth = { seth }: pkgs.stdenv.mkDerivation {
    name = "atd-to-seth-${version}";
    src = pkgs.lib.sourceByRegex ./. [
      "bin" "bin/atd-to-seth"
    ];

    nativeBuildInputs = [ makeWrapper ];
    buildInputs = with pkgs; [ nodejs ];

    buildPhase = "true";
    installPhase = ''
      mkdir -p $out
      cp -r ./bin $out/bin
      wrapProgram $out/bin/atd-to-seth \
        --set PATH "${with pkgs; makeBinPath [ coreutils gnugrep bash bc seth ]}"
    '';
  };

  atd-deploy = { seth }: runCommand "atd-deploy-${version}"
    { nativeBuildInputs = [ makeWrapper ]; }
    ''
      mkdir -p $out/bin
      cp ${./bin/atd-deploy} $out/bin/atd-deploy
      wrapProgram $out/bin/atd-deploy \
        --set PATH "${with pkgs; makeBinPath [
          coreutils gnugrep bash seth
          abi-to-dhall
          (atd-to-seth { inherit seth; })
        ]}"
    '';

  abi-to-dhall = pkgs.stdenv.mkDerivation {
    name = "abi-to-dhall-${version}";
    src = pkgs.lib.sourceByRegex ./. [
      "bin"   "bin/abi-to-dhall" "bin/atd"
      "dhall" "dhall/.*"
    ];

    nativeBuildInputs = [ makeWrapper dhall-haskell ];

    buildPhase = "true";
    installPhase = ''
      export XDG_CACHE_HOME="$PWD/.cache"
      mkdir -p $out/dhall "XDG_CACHE_HOME"

      ln -sf ${dhall-prelude} ./dhall/Prelude
      dhall <<<"./dhall/package.dhall" > $out/dhall/package.dhall

      cp -r ./bin $out/bin
      wrapProgram $out/bin/abi-to-dhall \
        --set _VERSION ${version} \
        --set PATH ${binPaths} \
        --set LIB_DIR $out/dhall \
        --set PRELUDE_PATH ${dhall-prelude}

      wrapProgram $out/bin/atd \
        --set _VERSION ${version} \
        --prefix PATH : ${atdBinPaths}
    '';
    passthru = {
      buildAbiToDhall = pkgs.callPackage ./dapp-build.nix { inherit abi-to-dhall; };
      deploy = atd-deploy;
      runtimes = {
        seth = atd-to-seth;
      };
    };
  };
in abi-to-dhall
