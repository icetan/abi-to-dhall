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
, solidityPackages ? []
, passthru ? {}
, ... } @ args:

let
  bins = [ seth ethsign dapp coreutils gnugrep gnused ];

  abiToDhallMerged = runCommand "${name}-abi-to-dhall-deploy"
    { nativeBuildInputs = [ abi-to-dhall findutils ]; }
    ''
    echo >&2 Building Dhall files from ABIs
    mkdir -p $out/dapp-out
    find ${
        builtins.concatStringsSep
          " "
          (map (x: "${x}/dapp/*/out") solidityPackages)
      } -maxdepth 1 -type f -exec ln -sf -t $out/dapp-out {} \;

    mkdir -p $out/abi-to-dhall
    abi-to-dhall deploy $out/dapp-out/*.abi 2> stderr.log \
      || { cat stderr.log; exit 1; }
    mv -t $out/abi-to-dhall ./atd
    '';

  linker = writeScriptBin "${name}-linker" ''
    #!${bash}/bin/bash
    exec ln -sfv -t . ${abiToDhallMerged}/abi-to-dhall/atd
  '';

  bundle = { src }: stdenv.mkDerivation {
    inherit src;
    name = "${name}-bundle";

    nativeBuildInputs = [ makeWrapper dhall-haskell ];
    buildInputs = bins;

    BIN_PATH = lib.makeBinPath bins;
    DAPP_OUT = "${abiToDhallMerged}/dapp-out";
    DAPP_SKIP_BUILD = "yes";

    buildPhase = ''
      ln -sf -t . ${abiToDhallMerged}/abi-to-dhall/*
      dhall text <<<"./main.dhall ./config.dhall" > deploy.sh
      chmod +x deploy.sh
    '';

    installPhase = ''
      mkdir -p $out/bin
      cp deploy.sh $out/bin/${name}
      wrapProgram $out/bin/${name} \
        --argv0 "${name}" \
        --set PATH "$BIN_PATH" \
        --set DAPP_OUT "$DAPP_OUT" \
        --set DAPP_SKIP_BUILD "$DAPP_SKIP_BUILD"
    '';

    checkPhase = ''
      ${shellcheck}/bin/shellcheck -x $out/bin/*
    '';
  };

  runner = runCommand "${name}-runner" {
      DAPP_OUT = "${abiToDhallMerged}/dapp-out";

      buildInputs = [ makeWrapper ];
      passthru = {
        inherit solidityPackages bundle linker;
      } // passthru;
    } ''
      makeWrapper ${abi-to-dhall}/bin/dhall-runner $out/bin/${name}-runner \
        --argv0 "${name}-runner" \
        --set DAPP_OUT "$DAPP_OUT" \
        --set ATD_PATH "${abiToDhallMerged}/abi-to-dhall/atd"
    '';
in runner // (removeAttrs args [ "solidityPackages" "passthru" ]))
