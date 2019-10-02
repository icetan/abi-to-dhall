let backend = ./lib/backend

let lib = ./lib/default

let Plan/run = lib.Plan/run

let Plan/runThen = lib.Plan/runThen

let Plan/runAll = lib.Plan/runAll

let Plan/optional = lib.Plan/optional

let Module = lib.Module

let Module/optional = lib.Module/optional

let Deploy = lib.Deploy

let Deploy/deploy = lib.Deploy/deploy

let types = ./lib/types

let DSToken = ./abi/DSToken

let DSGuard = ./abi/DSGuard

let Config = ./configSchema.dhall

let sig/mint =
      backend.hexToBytes32 (backend.sig "mint(address,uint256)")

let sig/burn =
      backend.hexToBytes32 (backend.sig "burn(address,uint256)")

let BaseOutput
      : Type
      = { token : types.address
        , guard : types.address
        }

let extraModule
      : Module BaseOutput
      =   λ(baseOutput : BaseOutput)
        → DSToken.create/bytes32
            (backend.hexToBytes32 (backend.asciiToHex "EXTRA_TOKEN"))
            (λ(token : types.address)

        → Plan/run
            [ DSToken.send/setAuthority/address token baseOutput.guard
            , DSToken.send/mint/address-uint256
                baseOutput.token
                baseOutput.guard
                (backend.naturalToUint256 (lib.ethToWei 1337))

            , types.address/output "EXTRA_TOKEN" token
            ]
        )

let baseModule
      : Module Config
      =   λ(c : Config)
        → DSToken.create/bytes32
            (backend.hexToBytes32 (backend.asciiToHex "BASE_TOKEN"))
            (λ(token : types.address)

        → DSGuard.create
            (λ(guard : types.address)

        → Plan/run
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

let rootModule
      : Module Config
      =   λ(c : Config)
        → DSToken.create/bytes32
            (backend.hexToBytes32 (backend.asciiToHex "ROOT_TOKEN"))
            (λ(token : types.address)

        → DSGuard.create
            (λ(guard : types.address)

        → Plan/runAll
            [ baseModule c
            , extraModule { token = token, guard = guard }
            ]
        ))

let deployments
      : Deploy Config
      = [ rootModule
        -- , Module/optional False Config extraModule
        ]

let deploy = Deploy/deploy Config deployments

in  λ(c : Config) → backend.render (deploy c)
