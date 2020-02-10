# ABI to Dhall Example

## Run

```sh
nix run -f . -c example-deploy testchain
```

## Development

```sh
nix-shell
nix-build
ln -s result/abi-to-dhall/atd .
```

Preview deployment AST:

```sh
atd ast \
  --input '(./dhall/schema.dhall).Config' ./config/config-testchain.json \
  --input '(./dhall/schema.dhall).Import' ./config/import-testchain.json \
  -- ./dhall/main.dhall > >(tee ast.json)
```

Run deploy against a testchain:

```sh
atd run seth --ast ast.json
```

## Project Structure

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

