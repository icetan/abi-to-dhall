let Optional/map = ./atd/Prelude/Optional/map

let atd = ./atd/package

let Address = atd.address

let addr = atd.address/build

let addr/out = atd.address/output

let Plan = atd.Plan

let Plan/buildThen = atd.Plan/buildThen

let Module = atd.Module

let Module/default = atd.Module/default

let StateModule = atd.StateModule

let ds-token = atd.contracts.ds-token

let DSToken = ds-token.DSToken

let DSToken/build = ds-token.DSToken/build

let DSToken/create/bytes32 = ds-token.DSToken/create/bytes32

let ds-guard = atd.contracts.ds-guard

let DSGuard = ds-guard.DSGuard

let DSGuard/build = ds-guard.DSGuard/build

let DSGuard/create = ds-guard.DSGuard/create

let schema = ./schema.dhall

let State = schema.State

let Config = schema.Config

let optionalAddr = Optional/map Text Address addr

let sig/mint =
      atd.hexToBytes32 (atd.sig "mint(address,uint256)")

let sig/burn =
      atd.hexToBytes32 (atd.sig "burn(address,uint256)")

let createToken
      : Optional Text → Module DSToken
      =   λ(tokenAddress: Optional Text)
        → Module/default
            DSToken
            (DSToken/create/bytes32 (atd.hexToBytes32 (atd.asciiToHex "EXAMPLE_TOKEN")))
            (Optional/map Address DSToken DSToken/build (optionalAddr tokenAddress))

let createGuard
      : Optional Text → Module DSGuard
      =   λ(guardAddress: Optional Text)
        → Module/default
            DSGuard
            DSGuard/create
            (Optional/map Address DSGuard DSGuard/build (optionalAddr guardAddress))

let guardModule
      : Config → StateModule State
      =   λ(conf : Config)
        → λ(return : State → Plan)
        → λ(state : State)

        → createToken state.tokenAddress
            (λ(token : DSToken)

        → createGuard state.guardAddress
            (λ(guard : DSGuard)

        → Plan/buildThen
            [ token.send/mint/address-uint256
                guard.address
                (atd.naturalToUint256 conf.mint)
            , token.send/setAuthority/address
                guard.address
            , guard.send/permit/address-address-bytes32
                (addr conf.auctionAddress)
                token.address
                sig/mint
            , guard.send/permit/address-address-bytes32
                (addr conf.auctionAddress)
                token.address
                sig/burn

            , addr/out "tokenAddress" token.address
            , addr/out "guardAddress" guard.address
            ]
            (return state)
      ))

in  { module = guardModule
    }
