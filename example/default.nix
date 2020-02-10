{ dappPkgs ? import (fetchGit {
    url = "https://github.com/dapphub/dapptools";
    ref = "dapp/0.26.0";
    rev = "eb2380c990179ada97fc1ee376ad6f2a32bfe833";
  }) {}
, abi-to-dhall ? import ../. {}
}:

let
  inherit (abi-to-dhall) buildAbiToDhall deploy;
  solidityPackages = builtins.attrValues
    (dappPkgs.callPackage ./dapp2.nix {}).deps;

in buildAbiToDhall {
  name = "example";
  src = ./.;

  inherit solidityPackages;

  # Select which contracts to compile
  abiFileGlobs = [
    "DSToken"
    "DSGuard"
  ];

  deployBin = deploy { inherit (dappPkgs) seth; };
}
