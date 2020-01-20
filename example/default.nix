{ pkgs ? (import ../pkgs.nix).pkgs
, backend ? "sh"
}:

let
  inherit (import ../. { inherit pkgs; }) buildAbiToDhall;
  solidityPackages = builtins.attrValues
    (pkgs.callPackage ./dapp2.nix {}).deps;

in buildAbiToDhall {
  inherit solidityPackages backend;
  name = "example";
  src = pkgs.lib.sourceByRegex ./. [ ".*\.dhall" ];
}
