let backend = ./lib/backend

let lib = ./lib/default

let Deploy/deploy = lib.Deploy/deploy

let Deploy/plan = lib.Deploy/plan

let types = ./lib/types

let DSToken = ./abi/DSToken

let DSGuard = ./abi/DSGuard

let Config = ./configSchema.dhall

let sig/mint =
      backend.hexToBytes32 (backend.sig "mint(address,uint256)")

let sig/burn =
      backend.hexToBytes32 (backend.sig "burn(address,uint256)")

let baseDeployment
      =   λ(c : Config)
        → DSToken.create/bytes32
            (backend.hexToBytes32 (backend.asciiToHex "BASE_TOKEN"))
            (λ(token : types.address)

        → DSGuard.create
            (λ(guard : types.address)

        → Deploy/plan
            [ DSToken.send/mint/address-uint256
                token
                guard
                (backend.naturalToUint256 (lib.ethToWei 1000000))
            , DSToken.send/setAuthority/address c.mcdGov guard
            , DSGuard.send/permit/address-address-bytes32
                guard
                c.mcdFlap
                c.mcdGov
                sig/mint
            , DSGuard.send/permit/address-address-bytes32
                guard
                c.mcdFlap
                c.mcdGov
                sig/burn

            , types.address/output "TOKEN" token
            , types.address/output "GUARD" guard
            ]
      ))

let extraDeployment
      =   λ(c : Config)
        → DSToken.create/bytes32
            (backend.hexToBytes32 (backend.asciiToHex "EXTRA_TOKEN"))
            (   λ(token : types.address)
              → Deploy/plan [ types.address/output "EXTRA_TOKEN" token ]
            )

let deployments = [ baseDeployment, extraDeployment ]

let deploy = Deploy/deploy Config deployments

in  λ(c : Config) → backend.render (deploy c)
