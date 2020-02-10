{ atd ? import ./.. {}
, example ? import ./. {}
, dapp2nix ? import (fetchGit {
    url = "https://github.com/icetan/dapp2nix";
    ref = "v2.1.7";
    rev = "5d433e6d5d8b89da808a51a3c8a0559893efbaf5";
  }) {}
, dappPkgs ? import (fetchGit {
    url = "https://github.com/dapphub/dapptools";
    ref = "dapp/0.26.0";
    rev = "eb2380c990179ada97fc1ee376ad6f2a32bfe833";
  }) {}
}@args:

example.shell {
  extraBuildInputs = [
    dapp2nix
    (atd.runtimes.seth { inherit (dappPkgs) seth; })
  ];
}
