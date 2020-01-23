{ lib, stdenv, makeWrapper, runCommand, writeScriptBin
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
  abiToDhallMerged = runCommand "${name}-abi-to-dhall"
    { nativeBuildInputs = [ abi-to-dhall findutils ]; }
    ''
    echo >&2 Building Dhall files from ABIs

    export XDG_CACHE_HOME="$PWD/.cache"
    mkdir -p $out/dapp-out "XDG_CACHE_HOME"

    find ${
      builtins.concatStringsSep
        " "
        (map (x: "${x}/dapp/*/out") solidityPackages)
    } -maxdepth 1 -type f -exec ln -sf -t $out/dapp-out {} \;

    abi-to-dhall --prefix "${name}" $out/dapp-out/*.abi

    mkdir -p ./atd/deps
    ${
      builtins.concatStringsSep
        "\n"
        (map
          (dep: ''
            ln -s "${dep}/abi-to-dhall" "./atd/deps/${dep.name}"
            ln -s -t ./atd/evm "${dep}"/abi-to-dhall/atd/evm/*
          '')
          deps)
    }

    mkdir -p $out/abi-to-dhall
    mv -t $out/abi-to-dhall ./atd
    '';

  runner = stdenv.mkDerivation {
    inherit src;
    name = "${name}-atd";
    nativeBuildInputs = [ makeWrapper ];

    ATD_MERGE = "${abiToDhallMerged}";

    installPhase = ''
      mkdir -p $out/abi-to-dhall/deps
      cp -r -t $out/abi-to-dhall ./*
      ln -s "$ATD_MERGE/dapp-out" $out/dapp-out
      ln -s "$ATD_MERGE/abi-to-dhall/atd" $out/abi-to-dhall/atd
      makeWrapper ${abi-to-dhall}/bin/atd $out/bin/${name}-atd \
        --set ATD_PREBUILT "$out/abi-to-dhall/atd"
    '';

    passthru = {
      inherit solidityPackages;
    } // passthru;
  };
in runner // (removeAttrs args [ "solidityPackages" "passthru" ]))
