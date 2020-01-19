let atd = ./atd/package

let Plan/run = atd.Plan/run

let Plan/runThen = atd.Plan/runThen

let Plan/runAll = atd.Plan/runAll

let Plan/optional = atd.Plan/optional

let Module = atd.Module

let Module/optional = atd.Module/optional

let Deploy = atd.Deploy

let Deploy/deploy = atd.Deploy/deploy

let DSToken = atd.abis.DSToken

let DSGuard = atd.abis.DSGuard

let Config = ./configSchema.dhall

let sig/mint =
      atd.hexToBytes32 (atd.sig "mint(address,uint256)")

let sig/burn =
      atd.hexToBytes32 (atd.sig "burn(address,uint256)")

let BaseOutput
      : Type
      = { token : DSToken.Type
        , guard : DSGuard.Type
        }

let extraModule
      : Module BaseOutput
      =   λ(baseOutput : BaseOutput)
        → DSToken.create/bytes32
            (atd.hexToBytes32 (atd.asciiToHex "EXTRA_TOKEN"))
            (λ(token : DSToken.Type)

        → Plan/run
            [ token.send/setAuthority/address baseOutput.guard.address
            , baseOutput.token.send/mint/address-uint256
                baseOutput.guard.address
                (atd.naturalToUint256 (atd.ethToWei 1337))

            , atd.address/output "EXTRA_TOKEN" token.address
            ]
        )

let baseModule
      : Module Config
      =   λ(c : Config)
        → DSToken.create/bytes32
            (atd.hexToBytes32 (atd.asciiToHex "BASE_TOKEN"))
            (λ(token : DSToken.Type)

        → DSGuard.create
            (λ(guard : DSGuard.Type)

        → Plan/run
            [ token.send/mint/address-uint256
                guard.address
                (atd.naturalToUint256 (atd.ethToWei 1000000))
            , (DSToken.build c.mcdGov).send/setAuthority/address guard.address
            , guard.send/permit/address-address-bytes32
                c.mcdFlap
                c.mcdGov
                sig/mint
            , guard.send/permit/address-address-bytes32
                c.mcdFlap
                c.mcdGov
                sig/burn

            , atd.address/output "TOKEN" token.address
            , atd.address/output "GUARD" guard.address
            ]
      ))

let rootModule
      : Module Config
      =   λ(c : Config)
        → DSToken.create/bytes32
            (atd.hexToBytes32 (atd.asciiToHex "ROOT_TOKEN"))
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

in  λ(c : Config) → atd.render (deploy c)
