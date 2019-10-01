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
        → DSGuard.create
            (λ(mcdGovGuard : address)

        → Multicall.create
            (λ(multicall : address)

        → Multicall.create
            (λ(multicall1 : address)

        → Multicall.create
            (λ(multicall2 : address)

        → RestrictedTokenFaucet.create/uint256
            (lib.toUint256 (lib.ethToWei 50))
            (λ(faucet : address)

        → RestrictedTokenFaucet.call/amt faucet
            (λ(faucetAmt : types.uint256)

        → (./abi/Spotter).create/address
            faucet
            (λ(spotter : address)

        → Deploy/plan
            [ DSToken.send/mint/address-uint256
                c.mcdGov
                faucet
                (lib.toUint256 (lib.ethToWei 1000000))
            , DSToken.send/setAuthority/address c.mcdGov mcdGovGuard
            , RestrictedTokenFaucet.send/gulp/address faucet c.mcdGov
            , DSGuard.send/permit/address-address-bytes32
                mcdGovGuard
                multicall1 -- c.mcdFlap
                multicall2 -- c.mcdGov
                sig/mint/address-uint256
            , DSGuard.send/permit/address-address-bytes32
                mcdGovGuard
                multicall1 -- c.mcdFlap
                multicall2 -- c.mcdGov
                sig/burn/address-uint256

            , lib.optionalVoid (Some (types.address/void multicall))
            , types.address/void spotter
            , types.uint256/void faucetAmt
            ]
      )))))))

let extraDeployment
    : Config → ChainableDeploy
    =   λ(c : Config)
      → DSGuard.create
          (λ(mjau : address)
      → Deploy/plan [ types.address/void mjau ])

let deployments = [ baseDeployment, extraDeployment ]

let deploy = Deploy/deploy Config deployments

in  { text = λ(c : Config) → backend.render (deploy c), ast = deploy }
