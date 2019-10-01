{ lib, stdenv, symlinkJoin, writeScriptBin, makeWrapper, runCommand
, perl, shellcheck
, coreutils, gnugrep, gnused, findutils
, solc
, dapp, ethsign, seth
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
, solidityPackages ? []
, passthru ? {}
, ... } @ args:

let
  bins = [ seth ethsign dapp coreutils gnugrep gnused ];

  # Symlink all solidity packages into one directory
  #depsMerged = symlinkJoin {
  #  name = "${name}-solidity-packages";
  #  paths = solidityPackages;
  #  nativeBuildInputs = [ findutils ];
  #  postBuild = ''
  #    echo POST MERGE BUILD
  #  '';
  #};

  abiToDhallMerged = runCommand "${name}-abi-to-dhall-deploy" { nativeBuildInputs = [ abi-to-dhall findutils ]; } ''
    echo >&2 Building Dhall files from ABIs
    mkdir -p $out/dapp-out
    find ${
        builtins.concatStringsSep
          " "
          (map (x: "${x}/dapp/*/out") solidityPackages)
      } -maxdepth 1 -type f -exec ln -sf -t $out/dapp-out {} \;

    mkdir -p $out/abi-to-dhall
    abi-to-dhall deploy $out/dapp-out/*.abi 2> /dev/null
    mv -t $out/abi-to-dhall ./lib ./abi
  '';

in stdenv.mkDerivation ({
  inherit name src;
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
      --set PATH "$BIN_PATH" \
      --set DAPP_OUT "$DAPP_OUT" \
      --set DAPP_SKIP_BUILD "$DAPP_SKIP_BUILD"
  '';

  checkPhase = ''
    ${shellcheck}/bin/shellcheck -x $out/bin/*
  '';

  passthru = {
    inherit solidityPackages;
  } // passthru;
} // (removeAttrs args [ "solidityPackages" "passthru" ])))
