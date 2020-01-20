{ lib, stdenv, makeWrapper, runCommand, writeScriptBin
, shellcheck, bash
, coreutils, gnugrep, gnused, findutils
, solc , dapp, ethsign, seth
, dhall-haskell, abi-to-dhall
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
, backend ? "sh"
, deps ? []
, solidityPackages ? []
, passthru ? {}
, ... } @ args:

let
  bins = [ seth ethsign dapp coreutils gnugrep gnused ];

  abiToDhallMerged = runCommand "${name}-abi-to-dhall-${backend}"
    { nativeBuildInputs = [ abi-to-dhall findutils ]; }
    ''
    echo >&2 Building Dhall files from ABIs
    mkdir -p $out/dapp-out
    find ${
        builtins.concatStringsSep
          " "
          (map (x: "${x}/dapp/*/out") solidityPackages)
      } -maxdepth 1 -type f -exec ln -sf -t $out/dapp-out {} \;

    abi-to-dhall ${backend} $out/dapp-out/*.abi 2> stderr.log \
      || { cat stderr.log; exit 1; }

    mkdir -p ./atd/deps
    ${
      builtins.concatStringsSep
        "\n"
        (map
          (dep:
            let dep' = dep.overrideAttrs (_: { inherit backend; });
            in "ln -s \"${dep'}/abi-to-dhall\" ./atd/deps/${dep'.name}")
          deps)
    }

    mkdir -p $out/abi-to-dhall
    mv -t $out/abi-to-dhall ./atd
    '';

#  bundle = stdenv.mkDerivation {
#    inherit src;
#    name = "${name}-bundle";
#
#    nativeBuildInputs = [ makeWrapper dhall-haskell ];
#    buildInputs = bins;
#
#    BIN_PATH = lib.makeBinPath bins;
#    DAPP_OUT = "${abiToDhallMerged}/dapp-out";
#    DAPP_SKIP_BUILD = "yes";
#
#    buildPhase = ''
#      ln -sf -t . ${abiToDhallMerged}/abi-to-dhall/*
#      dhall text <<<"./main.dhall ./config.dhall" > deploy.sh
#      chmod +x deploy.sh
#    '';
#
#    installPhase = ''
#      mkdir -p $out/bin
#      cp deploy.sh $out/bin/${name}
#      wrapProgram $out/bin/${name} \
#        --argv0 "${name}" \
#        --set PATH "$BIN_PATH" \
#        --set DAPP_OUT "$DAPP_OUT" \
#        --set DAPP_SKIP_BUILD "$DAPP_SKIP_BUILD"
#    '';
#
#    checkPhase = ''
#      ${shellcheck}/bin/shellcheck -x $out/bin/*
#    '';
#  };

  runner = stdenv.mkDerivation {
    inherit src;
    name = "${name}-atd";
    nativeBuildInputs = [ makeWrapper dhall-haskell ];

    ATD_MERGE = "${abiToDhallMerged}";

    installPhase = ''
      mkdir -p $out/abi-to-dhall/deps
      cp -r -t $out/abi-to-dhall ./*
      ln -s "$ATD_MERGE/dapp-out" $out/dapp-out
      ln -s "$ATD_MERGE/abi-to-dhall/atd" $out/abi-to-dhall/atd
      makeWrapper ${abi-to-dhall}/bin/atd $out/bin/${name}-atd \
        --run "rm -rf ./atd; ln -sfT $out/abi-to-dhall/atd ./atd"
    '';

    passthru = {
      inherit solidityPackages backend; # bundle;
    } // passthru;
  };
in runner // (removeAttrs args [ "solidityPackages" "passthru" ]))
