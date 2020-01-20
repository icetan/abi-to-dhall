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

### Generating code from ABIs

Deploy a `ds-token` and `ds-guard`.

Generate the Dhall code "backend" from the ABIs of the desired smart contracts.
In this case we use the `deploy` backend which will be able to generate a bash
script that does a deployment:

```sh
abi-to-dhall sh out/abi/{DSToken,DSGuard}.abi
```

Import the generated Dhall code and render a `Plan`. All generated Dhall code is
written to `./adt` and can be imported through the `./adt/package` file.

```sh
dhall <<EOF
let atd = ./atd/package

let DSToken = atd.abis.DSToken

let DSGuard = atd.abis.DSGuard

let plan
      = DSToken.create/bytes32
          (atd.hexToBytes32 (atd.asciiToHex "MyToken"))
          (λ(token : DSToken.Type)

      → DSGuard.create
          (λ(guard : DSGuard.Type)

      → atd.Plan/run
            [ token.send/setAuthority/address guard.address
            , (atd.address/output "TOKEN" token.address)
            , (atd.address/output "GUARD" guard.address)
            ]
      ))
in atd.render (atd.Plan/deploy plan)
EOF
```

### High level CLI

See `example` directory.

Print CLI usage:

```sh
atd
```
