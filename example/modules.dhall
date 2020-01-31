let Optional/map = ./atd/Prelude/Optional/map

let atd = ./atd/package

let Address = atd.Address

let Address/build = atd.Address/build

let Address/output = atd.Address/output

let Plan = atd.Plan

let Plan/build = atd.Plan/build

let Plan/buildThen = atd.Plan/buildThen

let Plan/concat = atd.Plan/concat

let Plan/outputs = atd.Plan/outputs

let Module = atd.Module

let Module/default = atd.Module/default

let ds-token = atd.contracts.ds-token

let DSToken = ds-token.DSToken

let DSToken/build = ds-token.DSToken/build

let DSToken/create/bytes32 = ds-token.DSToken/create/bytes32

let ds-guard = atd.contracts.ds-guard

let DSGuard = ds-guard.DSGuard

let DSGuard/build = ds-guard.DSGuard/build

let DSGuard/create = ds-guard.DSGuard/create

let schema = ./schema.dhall

let Input = schema.Input

let Output = schema.Output

let Config = schema.Config

let sig/mint = atd.sig "mint(address,uint256)"

let sig/burn = atd.sig "burn(address,uint256)"

let createToken
    : Optional Address → Module DSToken
    =   λ(tokenAddress : Optional Address)
      → Module/default
          DSToken
          (DSToken/create/bytes32 (atd.Bytes32/fromHex (atd.asciiToHex "EXAMPLE_TOKEN")))
          ( Optional/map
              Address
              DSToken
              DSToken/build
              tokenAddress
          )

let createGuard
    : Optional Address → Module DSGuard
    =   λ(guardAddress : Optional Address)
      → Module/default
          DSGuard
          DSGuard/create
          ( Optional/map
              Address
              DSGuard
              DSGuard/build
              guardAddress
          )

let outputAddresses
    =   λ(o : Output)
      → Plan/outputs Address Address/output (toMap o)

let optionalAddress = Optional/map Text Address Address/build

let guardModule
      : Config → Input → Module Output
      =   λ(conf : Config)
        → λ(input : Input)
        → λ(return : Output → Plan)

        → createToken (optionalAddress input.tokenAddress)
            (λ(token : DSToken)

        → createGuard (optionalAddress input.guardAddress)
            (λ(guard : DSGuard)

        → let send = Plan/build
            [ token.send/mint/address-uint256
                guard.address
                (atd.Uint256/build conf.mint)

            , token.send/setAuthority/address
                guard.address

            , guard.send/permit/address-address-bytes32
                conf.auctionAddress
                token.address
                (atd.Bytes32/fromHex sig/mint)

            , guard.send/permit/address-address-bytes32
                conf.auctionAddress
                token.address
                (atd.Bytes32/fromHex sig/burn)
            ]

          let output =
            { tokenAddress = token.address
            , guardAddress = guard.address
            }

          in Plan/concat
            [ send
            , outputAddresses output
            , return output
            ]
      ))

in  { module = guardModule }
