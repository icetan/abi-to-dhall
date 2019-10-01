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

Deploy a `DSToken`.

```sh
abi-to-dhall deploy out/abi/{DSToken,Spotter}.abi
dhall <<EOF
let backend = ./lib/backend

let types = ./lib/types

let lib = ./lib/default

let DSToken = ./abi/DSToken

let Spotter = ./abi/Spotter

let deployment
      = DSToken.create/bytes32
          (backend.hexToBytes32 (backend.asciiToHex "MyToken"))
          (λ(myToken : types.address)

      → Spotter.create/address
          myToken
          (λ(spotter : types.address)

      → lib.Deploy/plan
            [ (types.address/void spotter) ]
      ))


in backend.render (lib.Deploy/chain [ deployment ] 0)
EOF
```
