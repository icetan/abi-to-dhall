let backend = ./lib/backend

let lib = ./lib/default

let ChainableDeploy = lib.ChainableDeploy

let Deploy/deploy = lib.Deploy/deploy

let Deploy/plan = lib.Deploy/plan

let types = ./lib/types

let address = types.address

let RestrictedTokenFaucet = ./abi/RestrictedTokenFaucet

let DSToken = ./abi/DSToken

let Multicall = ./abi/Multicall

let DSGuard = ./abi/DSGuard

let Config = ./configSchema.dhall

let sig/mint/address-uint256 =
      backend.hexToBytes32 (backend.sig "mint(address,uint256)")

let sig/burn/address-uint256 =
      backend.hexToBytes32 (backend.sig "burn(address,uint256)")

let baseDeployment
      : Config → ChainableDeploy
      =   λ(c : Config)
        → DSToken.create/bytes32
            (backend.hexToBytes32 (backend.asciiToHex "MCD"))
            (λ(mcd : address)

        → DSGuard.create
            (λ(mcdGovGuard : address)

        → Multicall.create
            (λ(multicall : address)

        → RestrictedTokenFaucet.create/uint256
            (backend.naturalToUint256 (lib.ethToWei 50))
            (λ(faucet : address)

        → RestrictedTokenFaucet.call/amt faucet
            (λ(faucetAmt : types.uint256)

        → (./abi/Spotter).create/address
            faucet
            (λ(spotter : address)

        → Deploy/plan
            [ DSToken.send/mint/address-uint256
                mcd
                faucet
                (backend.naturalToUint256 (lib.ethToWei 1000000))
            , DSToken.send/setAuthority/address c.mcdGov mcdGovGuard
            , DSGuard.send/permit/address-address-bytes32
                mcdGovGuard
                c.mcdFlap
                c.mcdGov
                sig/mint/address-uint256
            , DSGuard.send/permit/address-address-bytes32
                mcdGovGuard
                c.mcdFlap
                c.mcdGov
                sig/burn/address-uint256

            , types.address/output "MULTICALL" multicall
            , types.address/output "SPOTTER" spotter
            , types.uint256/output "FAUCET_AMOUNT" faucetAmt
            ]
      ))))))

let extraDeployment
    : Config → ChainableDeploy
    =   λ(c : Config)
      → DSGuard.create
          (   λ(mjau : address)
            → Deploy/plan [ types.address/output "MJAU_GUARD" mjau ]
          )

let deployments = [ baseDeployment, extraDeployment ]

let deploy = Deploy/deploy Config deployments

in  λ(c : Config) → backend.render (deploy c)
