let types = ./atd/types

let PipDeploy : Type =
    < Value :
        { contract
            : types.address
        , price
            : Natural
        }
    | Median :
        { contract
            : types.address
        , signers
            : List types.address
        }
    >

let token = 
    { name : Text
    , pipDeploy : PipDeploy
    }
--     "ETH": {
--       "pipDeploy": {
--         "type": "value",
--         "price": "150",
--         "signers": [
--           "0x005B903dAdfD96229CBa5EB0e5Aa75C578e8F968",
--           "0x25310bC78B9347F97DC664b46E5D4602a6De5f2C",
--           "0x74B12Eeb596831796Beb1B36FC96DCCa815523B8",
--           "0xe709290634dE56a55d9826d35A9e677Fea5422EC",
--           "0x18753d13f14b80eb3d8ea96d4367957bb588d410",
--           "0x5874f6a09271cdb4e1a13ef3d402df6912863244",
--           "0x62ccadc1187593d0553398fabfa7ba41eb435ad2"
--         ]
--       },
--       "ilks": {
--         "A": {
--           "mat": "150",
--           "line": "100000",
--           "dust": "0",
--           "duty": "5",
--           "chop": "5",
--           "lump": "1.5",
--           "beg": "1",
--           "ttl": "3600",
--           "tau": "172800"
--         },
--         "B": {
--           "mat": "200",
--           "line": "100000",
--           "dust": "0",
--           "duty": "4",
--           "chop": "5",
--           "lump": "1.5",
--           "beg": "1",
--           "ttl": "3600",
--           "tau": "172800"
--         },
--         "C": {
--           "mat": "120",
--           "line": "100000",
--           "dust": "0",
--           "duty": "10",
--           "chop": "5",
--           "lump": "1.5",
--           "beg": "1",
--           "ttl": "3600",
--           "tau": "172800"
--         }
--       }
--     },

in  { mcdGov : types.address
    , mcdFlop: types.address
    , mcdFlap: types.address
    , DEPLOY_RESTRICTED_FAUCET : Bool
    , proxyRegistry : Optional types.address
    }
