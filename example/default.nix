{ pkgs ? (import ../pkgs.nix).pkgs
}:

let
  inherit (import ../. { inherit pkgs; }) buildAbiToDhall;
  solidityPackages = builtins.attrValues
    (pkgs.callPackage ./dapp2.nix {}).deps;

in buildAbiToDhall {
  inherit solidityPackages;
  name = "example";
  src = pkgs.lib.sourceByRegex ./. [ ".*\.dhall" ];
}
