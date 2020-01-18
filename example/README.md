# ABI to Dhall Example

## Build

```sh
nix-build
```

## Run

```sh
result/bin/abi-to-dhall-example
```

## Edit

`main.dhall`

The entrypoint script.

`configSchema.dhall`

The schema defining the structure of `config.dhall`.

`config.dhall`

The config values to be compiled with `main.dhall`.
