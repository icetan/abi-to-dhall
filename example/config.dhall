let atd = ./atd/package

in  { mcdGov =
        atd.address/build "0x0000000000000000000000000000000000000001"
    , mcdFlop =
        atd.address/build "0x0000000000000000000000000000000000000002"
    , mcdFlap =
        atd.address/build "0x0000000000000000000000000000000000000003"
    , DEPLOY_RESTRICTED_FAUCET =
        True
    , proxyRegistry =
        Some (atd.address/build "0x0000000000000000000000000000000000000004")
    }
