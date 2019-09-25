let List/concatMap = ~/src/dhall-lang/Prelude/List/concatMap

let lib = ./lib/default

let renderLib = ./lib/render

let types = ./lib/types

let Config = ./configSchema.dhall

let RestrictedTokenFaucet = ./abi/RestrictedTokenFaucet

let DSToken = ./abi/DSToken

let DSGuard = ./abi/DSGuard

let Multicall = ./abi/Multicall

let DSGuard = ./abi/DSGuard

let DSProxyFactory = ./abi/DSProxyFactory

let ProxyRegistry = ./abi/ProxyRegistry

let DssProxyActions = ./abi/DssProxyActions

let mcdGovGuard = DSGuard.create "MCD_GOV_GUARD"

let mcdIou =
      DSToken.create/bytes32
      "MCD_IOU"
      (renderLib.bytes32FromHex (renderLib.asciiToHex "IOU"))

let proxyFactory = DSProxyFactory.create "PROXY_FACTORY"

let proxyRegistry = ProxyRegistry.create/address "PROXY_REGISTRY" proxyFactory

let multicall = Multicall.create "MULTICALL"

let faucet =
      RestrictedTokenFaucet.create/uint256
      "FAUCET"
      (lib.toUint256 (lib.ethToWei 50))

let sig_mint/address/uint256 =
      renderLib.bytes32FromHex (renderLib.sig "mint(address,uint256)")

let sig_burn/address/uint256 =
      renderLib.bytes32FromHex (renderLib.sig "burn(address,uint256)")

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
        , lib.optionalVoid (Some (renderLib.addressToVoid multicall))
        ]

let deploy =
        λ(deploys : List (Config → List types.void))
      → λ(config : Config)
      → renderLib.toBash
        ( List/concatMap
          (Config → List types.void)
          types.void
          (λ(d : Config → List types.void) → d config)
          deploys
        )

in  deploy [ baseDeployment ]
