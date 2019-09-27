let List/concatMap =
        ./lib/Prelude/List/concatMap
      ? https://prelude.dhall-lang.org/List/concatMap

let abi-to-dhall = ../dhall/package.dhall

let backend : abi-to-dhall.abiSchema.BackendUtil = ./lib/backend

let lib = ./lib/default

let types = ./lib/types

let RestrictedTokenFaucet = ./abi/RestrictedTokenFaucet

let DSToken = ./abi/DSToken

let Multicall = ./abi/Multicall

let DSGuard = ./abi/DSGuard

let Config = ./configSchema.dhall

let mcdGovGuard = DSGuard.create "MCD_GOV_GUARD"

let multicall = Multicall.create "MULTICALL"

let faucet =
      RestrictedTokenFaucet.create/uint256
        "FAUCET"
        (lib.toUint256 (lib.ethToWei 50))

let sig_mint/address/uint256 =
      backend.bytes32FromHex (backend.sig "mint(address,uint256)")

let sig_burn/address/uint256 =
      backend.bytes32FromHex (backend.sig "burn(address,uint256)")

let baseDeployment =
        λ(c : Config)
      → [ DSToken.send/mint/address/uint256
            c.mcdGov
            faucet
            (lib.toUint256 (lib.ethToWei 1000000))
        , DSToken.send/setAuthority/address c.mcdGov mcdGovGuard
        , RestrictedTokenFaucet.send/gulp/address faucet c.mcdGov
        , DSGuard.send/permit/address/address/bytes32
            mcdGovGuard
            c.mcdFlop
            c.mcdGov
            sig_mint/address/uint256
        , DSGuard.send/permit/address/address/bytes32
            mcdGovGuard
            c.mcdFlap
            c.mcdGov
            sig_burn/address/uint256
        , lib.optionalVoid (Some (backend.addressToVoid multicall))
        ]

let deploy =
        λ(deploys : List (Config → List types.void))
      → λ(config : Config)
      → backend.render
          ( List/concatMap
              (Config → List types.void)
              types.void
              (λ(d : Config → List types.void) → d config)
              deploys
          )

in  deploy [ baseDeployment ]
