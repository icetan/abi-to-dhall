# ABI to Dhall Example

## Build

```sh
nix-build
```

## Run

```sh
result/bin/example-atd print -- ./main.dhall ./config.dhall
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

