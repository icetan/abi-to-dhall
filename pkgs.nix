rec {
  dappPkgsSrc = fetchGit {
    url = "https://github.com/dapphub/dapptools";
    ref = "dapp/0.22";
    rev = "138946e3323376d7e3acf7536b094b0108b81636";
    #ref = "dapp/0.25";
    #rev = "5c9acddd6bde407db20a5125de270d38a9ee86d5";
  };

  pkgs = import dappPkgsSrc {};
}
