{ atd ? import ./.. {}
, example ? import ./. {}
, dapp2nix ? import (fetchGit {
    url = "https://github.com/icetan/dapp2nix";
    ref = "v2.1.7";
    rev = "5d433e6d5d8b89da808a51a3c8a0559893efbaf5";
  }) {}
}@args:

example.shell {
  extraBuildInputs = [ dapp2nix ];
}
