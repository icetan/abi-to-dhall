let types = ./lib/typeConstructors

in  { mcdGov =
        types.address "0x000000000001"
    , mcdFlop =
        types.address "0x000000000002"
    , mcdFlap =
        types.address "0x000000000003"
    , DEPLOY_RESTRICTED_FAUCET =
        True
    , proxyRegistry =
        Some (types.address "0x000000000004")
    }
