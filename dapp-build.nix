{ lib, stdenv, runCommand, writeScriptBin, symlinkJoin, mkShell
, findutils, shellcheck, bash
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
, src ? null
, deps ? []
, solidityPackages ? []
, abiFileGlobs ? [ "*" ]
, deployBin ? null
, passthru ? {}
, ... } @ args:

let
  filteredSrc = lib.sourceByRegex src [ "dhall" "dhall/.*" "config" "config/.*" ];

  buildDappPackage = dappPkg: runCommand "${name}-${dappPkg.name}-dapp-to-dhall"
    { nativeBuildInputs = [ abi-to-dhall findutils ]; }
    ''
      echo >&2 "Building Dhall files from ABIs (${name}/${dappPkg.name})"

      export XDG_CACHE_HOME="$PWD/.cache"
      mkdir -p "XDG_CACHE_HOME"

      dappOut="$out/abi-to-dhall/dapp-out/${dappPkg.name}"
      mkdir -p "$dappOut"
      find -L ${dappPkg}/dapp/*/out -maxdepth 1 -type f -exec ln -s -t "$dappOut" {} \;
      abi-to-dhall --module "${name}" --namespace "${dappPkg.name}" $(find -L "$dappOut" -type f ${
        lib.concatMapStringsSep " -or " (x: "-name \"${x}.abi\"") abiFileGlobs
      })
      mv -t $out/abi-to-dhall ./atd
    '';

  atdPackages = map buildDappPackage solidityPackages;

  shell = overrideOverrideAttrs (
    { buildInputs ? [ abi-to-dhall ] ++ (lib.optional (deployBin != null) deployBin)
    , extraBuildInputs ? []
    , shellHook ? ""
    , ...
    } @ args: mkShell {
      buildInputs = buildInputs ++ extraBuildInputs;
      shellHook = ''
        export ATD_ABI_DIR="$PWD/result/abi-to-dhall/dapp-out"
      '' + shellHook;
    } // args);

  merged = symlinkJoin {
    name = "${name}-abi-to-dhall";
    paths = atdPackages;
    nativeBuildInputs = [ abi-to-dhall findutils ];
    passthru = {
      inherit solidityPackages shell;
    } // passthru;

    postBuild = ''
      export XDG_CACHE_HOME="$PWD/.cache"
      mkdir -p "XDG_CACHE_HOME"

      mkdir -p $out/abi-to-dhall $out/bin
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
      ${
        lib.optionalString
          (src != null)
          "cp -r -t . ${filteredSrc}/*"
      }
      ${
        if (deployBin != null) then ''
          echo "#!${bash}/bin/bash
          set -eo pipefail
          export ATD_NO_LINK=1
          export ATD_PATH=$out/abi-to-dhall/atd
          export DHALL_DIR=$out/abi-to-dhall/dhall
          export CONFIG_DIR=$out/abi-to-dhall/config
          exec ${deployBin}/bin/atd-deploy \"\$@\"
          " > $out/bin/${name}-deploy
          chmod +x $out/bin/${name}-deploy
        '' else ""
      }
    '';
  };
in merged // (removeAttrs args [ "solidityPackages" "passthru" ]))
