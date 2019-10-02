# abi-to-dhall

Generate Dhall functions from Solidity ABI files

## Why

I wanted a type safe way of generating scripts and other off-chain data that
interacts or relates to Ethereum smart contracts.

The main use case being deployment scripts. How to make sure that the right
types are passed to a smart contract function call.

## Install

```sh
nix-env -i -f https://github.com/icetan/abi-to-dhall/tarball/master
```

## Usage

Deploy a `ds-token` and `ds-guard`.

```sh
abi-to-dhall deploy out/abi/{DSToken,DSGuard}.abi
dhall <<EOF
let backend = ./lib/backend

let types = ./lib/types

let lib = ./lib/default

let DSToken = ./abi/DSToken

let DSGuard = ./abi/DSGuard

let plan
      = DSToken.create/bytes32
          (backend.hexToBytes32 (backend.asciiToHex "MyToken"))
          (λ(token : types.address)

      → DSGuard.create
          (λ(guard : types.address)

      → lib.Plan/run
            [ DSToken.send/setAuthority/address token guard
            , (types.address/output "TOKEN" token)
            , (types.address/output "GUARD" guard)
            ]
      ))
in backend.render (lib.Plan/deploy plan)
EOF
```
