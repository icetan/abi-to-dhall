{ dappPkgsSrc ? fetchGit {
    url = "https://github.com/dapphub/dapptools";
    ref = "dapp/0.22.0";
    rev = "138946e3323376d7e3acf7536b094b0108b81636";
  }
, pkgs ? import dappPkgsSrc {}
}:

let
  inherit (import ../. { inherit pkgs; }) buildAbiToDhall;
  solidityPackages = builtins.attrValues
    (pkgs.callPackage ./dapp2.nix {}).deps;

in buildAbiToDhall {
  name = "example";
  src = pkgs.lib.sourceByRegex ./. [ ".*\.dhall" ];

  inherit solidityPackages;
  abiFileGlobs = [
    "DSToken"
    "DSGuard"
  ];
}
