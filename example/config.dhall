let types = ./lib/types

in  { mcdGov =
        types.address/build "0x000000000001"
    , mcdFlop =
        types.address/build "0x000000000002"
    , mcdFlap =
        types.address/build "0x000000000003"
    , DEPLOY_RESTRICTED_FAUCET =
        True
    , proxyRegistry =
        Some (types.address/build "0x000000000004")
    }
