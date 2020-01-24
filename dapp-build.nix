{ lib, stdenv, makeWrapper, runCommand, writeScriptBin, symlinkJoin
, findutils, shellcheck
, abi-to-dhall
}:

let
  inherit (builtins) attrNames attrValues elemAt length;

  overrideOverrideAttrs = f: attrs: (f attrs) // {
    overrideAttrs = f_: overrideOverrideAttrs f (attrs // (f_ attrs));
  };
in

overrideOverrideAttrs (
{ name
, src
, deps ? []
, solidityPackages ? []
, passthru ? {}
, ... } @ args:

let
  buildDappPackage = dappPkg: runCommand "${name}-${dappPkg.name}-dapp-to-dhall"
    { nativeBuildInputs = [ abi-to-dhall findutils ]; }
    ''
      echo >&2 "Building Dhall files from ABIs (${name}/${dappPkg.name})"

      export XDG_CACHE_HOME="$PWD/.cache"
      mkdir -p "XDG_CACHE_HOME"

      dappOut="$out/abi-to-dhall/dapp-out/${dappPkg.name}"
      mkdir -p "$dappOut"
      find -L ${dappPkg}/dapp/*/out -maxdepth 1 -type f -exec ln -s -t "$dappOut" {} \;
      abi-to-dhall --module "${name}" --namespace "${dappPkg.name}" "$dappOut"/*.abi
      mv -t $out/abi-to-dhall ./atd
    '';

  atdPackages = map buildDappPackage solidityPackages;

  abiToDhallMerged = symlinkJoin {
    name = "${name}-abi-to-dhall";
    paths = atdPackages;
    nativeBuildInputs = [ abi-to-dhall findutils ];
    postBuild = ''
      export XDG_CACHE_HOME="$PWD/.cache"
      mkdir -p "XDG_CACHE_HOME"

      cd $out/abi-to-dhall

      abi-to-dhall --update-package

      mkdir -p ./atd/dep
      ${
        builtins.concatStringsSep
          "\n"
          (map
            (dep: ''
              ln -s "${dep}/abi-to-dhall" "./atd/dep/${dep.name}"
              ln -s -t ./atd/evm "${dep}"/abi-to-dhall/atd/evm/*
            '')
            deps)
      }
    '';
  };

  runner = stdenv.mkDerivation {
    inherit src;
    name = "${name}-atd";
    nativeBuildInputs = [ makeWrapper ];

    ATD_MERGE = "${abiToDhallMerged}";

    installPhase = ''
      mkdir -p $out/abi-to-dhall
      cp -r -t $out/abi-to-dhall ./*
      ln -sT "$ATD_MERGE/abi-to-dhall/dapp-out" $out/abi-to-dhall/dapp-out
      ln -sT "$ATD_MERGE/abi-to-dhall/atd" $out/abi-to-dhall/atd
      makeWrapper ${abi-to-dhall}/bin/atd $out/bin/${name}-atd \
        --set ATD_PREBUILT "$out/abi-to-dhall/atd"
    '';

    passthru = {
      inherit solidityPackages;
    } // passthru;
  };
in runner // (removeAttrs args [ "solidityPackages" "passthru" ]))
