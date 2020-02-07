 # abi-to-dhall

Generate a Dhall based DSL for deploying Ethereum contracts.

## Why

I wanted a type safe way of generating scripts and other off-chain data that
interacts or relates to Ethereum smart contracts.

The main use case being deployment. How to make sure that the right types
are passed to a smart contract function call.

## How

<!--[graph-easy --boxart
graph { flow: down }
[Contract ABIs]
-> [abi-to-dhall]
-> [Dhall DSL]
-> [JSON AST]
-> [Runtime]
-> [Deploy Output]
[Dhall Deploy Code] -> [Dhall DSL]
]-->
                              ┌───────────────┐
                              │ Contract ABIs │
                              └───────────────┘
                                │
                                │
                                ∨
                              ┌───────────────┐
                              │ abi-to-dhall  │
                              └───────────────┘
                                │
                                │
                                ∨
    ┌───────────────────┐     ┌───────────────┐
    │ Dhall Deploy Code │ ──> │   Dhall DSL   │
    └───────────────────┘     └───────────────┘
                                │
                                │
                                ∨
                              ┌───────────────┐
                              │   JSON AST    │
                              └───────────────┘
                                │
                                │
                                ∨
                              ┌───────────────┐
                              │    Runtime    │
                              └───────────────┘
                                │
                                │
                                ∨
                              ┌───────────────┐
                              │ Deploy Output │
                              └───────────────┘



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
abi-to-dhall out/abi/{DSToken,DSGuard}.abi
```

Import the generated Dhall DSL code and render a `Plan`. All generated
Dhall code is written to `./atd` and can be imported through the `./atd/package`
file.

```sh
dhall <<EOF
let atd = ./atd/package

let DSToken = atd.contracts.DSToken

let DSToken/create/bytes32 = atd.contracts.DSToken/create/bytes32

let DSGuard = atd.contracts.DSGuard

let DSGuard/create = atd.contracts.DSGuard/create

let plan
      = DSToken/create/bytes32
          (atd.hexToBytes32 (atd.asciiToHex "MyToken"))
          (λ(token : DSToken)

      → DSGuard/create
          (λ(guard : DSGuard)

      → atd.Plan/concat
            [ token.send/setAuthority/address guard.address
            , atd.Plan/build
              [ (atd.Address/output "TOKEN" token.address)
              , (atd.Address/output "GUARD" guard.address)
              ]
            ]
      ))
in atd.render (atd.Plan/run plan)
EOF
```

### High level CLI

See `example` directory.

Print CLI usage:

```sh
atd
```

## Semantics

### Void

### Run

### Plan

### Module

## EVM Types

  - Address
  - Uint
  - Int
  - Bytes32
