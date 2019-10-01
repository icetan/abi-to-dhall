rec {
  dappPkgsSrc = fetchGit {
    url = "https://github.com/dapphub/dapptools";
    rev = "5c9acddd6bde407db20a5125de270d38a9ee86d5";
  };

  #nixpkgs = <nixpkgs>;
  #pkgs = import nixpkgs {
  #  overlays = [ (import "${dappPkgsSrc}/overlay.nix") ];
  #};

  pkgs = import dappPkgsSrc {};
}
