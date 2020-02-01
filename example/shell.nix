{ pkgs ? import <nixpkgs> {}
, atd ? import ./.. {}
, example ? import ./. {}
, dapp2nix ? import (fetchGit {
    url = "https://github.com/icetan/dapp2nix";
    ref = "v2.1.7";
    rev = "5d433e6d5d8b89da808a51a3c8a0559893efbaf5";
  }) {}
}@args:

let
  dependenciesOnly = example.overrideAttrs (attrs: { src = null; });

in pkgs.mkShell {
  buildInputs = [
    atd
    dependenciesOnly
    dapp2nix
  ];

  shellHook = ''
    run-example-atd() {
      rm -f atd
      example-atd $1 \
        --input \
          '(./schema.dhall).Config' \
          "''${2:-./config.json}" \
        --input \
          '(./schema.dhall).Input' \
          "''${3:-./empty.json}" \
        -- ./main.dhall
    }

    example-ast() {
      run-example-atd "ast" "$@"
    }

    example-run-seth() {
      run-example-atd "run seth" "$@"
    }

    example-run-estimate() {
      run-example-atd "run seth --args --estimate ;" "$@"
    }

    example-print-seth() {
      run-example-atd "print seth" "$@"
    }
  '';
}
