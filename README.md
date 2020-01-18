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

Generate the Dhall code "backend" from the ABIs of the desired smart contracts.
In this case we use the `deploy` backend which will be able to generate a bash
script that does a deployment:

```sh
abi-to-dhall deploy out/abi/{DSToken,DSGuard}.abi
```

Import the generated Dhall code and render a `Plan` using the backend. The smart
contract interfaces are written to `./abi/*` and the backend and other generated
helpers like type constructors are written to `./lib/*`.

```sh
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
