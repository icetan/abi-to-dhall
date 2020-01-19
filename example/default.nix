{ pkgs ? (import ../pkgs.nix).pkgs
}:

let
  inherit (import ../. { inherit pkgs; }) buildAbiToDhall;
  solidityPackages = builtins.attrValues
    (pkgs.callPackage ./dapp2.nix {}).deps;

  runner = buildAbiToDhall {
    inherit solidityPackages;
    name = "atd-example";
  };
in {
  inherit runner;
  inherit (runner) linker;
  bundle = runner.bundle {
    src = pkgs.lib.sourceByRegex ./. [ ".*\.dhall" ];
  };
}
