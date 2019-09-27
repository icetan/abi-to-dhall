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
abi-to-dhall deploy out/abi/DSToken.abi
dhall | bash <<EOF
let backend = ./lib/backend

let DSToken = ./abi/DSToken

let myToken = DSToken.create "MY_TOKEN"

in backend.render [ (backend.addressToVoid myToken) ]
EOF
```
