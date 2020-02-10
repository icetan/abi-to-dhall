# ABI to Dhall Example

## Build

```sh
nix-build
```

## Run

Preview deployment AST:

```sh
nix-shell
atd-deploy testchain
```

## Development

Deploy using `seth` runtime:

```sh
atd run seth \
  --input '(./dhall/schema.dhall).Config' ./config/config-testchain.json \
  --input '(./dhall/schema.dhall).Import'  ./config/import-testchain.json \
  -- ./dhall/main.dhall
```

## Structure

`dhall/`

Directory containing Dhall deploy code.

`main.dhall`

Entry point for renderer.

`modules.dhall`

A collection of deployment modules that can be reused.

`schema.dhall`

Schema describing config and import format.

`config/`

Directory containing config and import JSON files.

`config-testchain.json`

The config values that will be passed to `main.dhall`.

`import-testchain.json`

The contract addresses that will be passed to `main.dhall` as the second
argument.

