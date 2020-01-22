# ABI to Dhall Example

## Build

```sh
nix-build
```

## Run

Preview deployment AST:

```sh
result/bin/example-atd ast -- ./main.dhall ./config.dhall
```

Deploy using `seth` runtime (you will need to install `dapptools` first):

```sh
result/bin/example-atd run seth -- ./main.dhall ./config.dhall
```

## Structure

`modules.dhall`

A collection of deployment plans that can be reused.

`main.dhall`

Entry point for renderer.

`config.dhall`

The config values that should be passed to `./main.dhall`.

`configSchema.dhall`

Schema describing config shape.

