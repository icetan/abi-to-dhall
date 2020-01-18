let backend = ./atd/backend

let lib = ./atd/lib

let types = ./atd/types

let Plan/run = lib.Plan/run

let Plan/runThen = lib.Plan/runThen

let Plan/runAll = lib.Plan/runAll

let Plan/optional = lib.Plan/optional

let Module = lib.Module

let Module/optional = lib.Module/optional

let Deploy = lib.Deploy

let Deploy/deploy = lib.Deploy/deploy

let DSToken = ./atd/abi/DSToken

let DSGuard = ./atd/abi/DSGuard

let Config = ./configSchema.dhall

let sig/mint =
      backend.hexToBytes32 (backend.sig "mint(address,uint256)")

let sig/burn =
      backend.hexToBytes32 (backend.sig "burn(address,uint256)")

let BaseOutput
      : Type
      = { token : DSToken.Type
        , guard : DSGuard.Type
        }

let extraModule
      : Module BaseOutput
      =   λ(baseOutput : BaseOutput)
        → DSToken.create/bytes32
            (backend.hexToBytes32 (backend.asciiToHex "EXTRA_TOKEN"))
            (λ(token : DSToken.Type)

        → Plan/run
            [ token.send/setAuthority/address baseOutput.guard.address
            , baseOutput.token.send/mint/address-uint256
                baseOutput.guard.address
                (backend.naturalToUint256 (lib.ethToWei 1337))

            , types.address/output "EXTRA_TOKEN" token.address
            ]
        )

let baseModule
      : Module Config
      =   λ(c : Config)
        → DSToken.create/bytes32
            (backend.hexToBytes32 (backend.asciiToHex "BASE_TOKEN"))
            (λ(token : DSToken.Type)

        → DSGuard.create
            (λ(guard : DSGuard.Type)

        → Plan/run
            [ token.send/mint/address-uint256
                guard.address
                (backend.naturalToUint256 (lib.ethToWei 1000000))
            , (DSToken.build c.mcdGov).send/setAuthority/address guard.address
            , guard.send/permit/address-address-bytes32
                c.mcdFlap
                c.mcdGov
                sig/mint
            , guard.send/permit/address-address-bytes32
                c.mcdFlap
                c.mcdGov
                sig/burn

            , types.address/output "TOKEN" token.address
            , types.address/output "GUARD" guard.address
            ]
      ))

let rootModule
      : Module Config
      =   λ(c : Config)
        → DSToken.create/bytes32
            (backend.hexToBytes32 (backend.asciiToHex "ROOT_TOKEN"))
            (λ(token : DSToken.Type)

        → DSGuard.create
            (λ(guard : DSGuard.Type)

        → Plan/runAll
            [ baseModule c
            , Plan/optional False (extraModule { token = token, guard = guard })
            ]
        ))

let deployments
      : Deploy Config
      = [ rootModule
        -- , Module/optional False Config extraModule
        ]

let deploy = Deploy/deploy Config deployments

in  λ(c : Config) → backend.render (deploy c)
