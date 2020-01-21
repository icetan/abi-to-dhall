let atd = ./atd/package

let PipDeploy : Type =
    < Value :
        { contract
            : atd.address
        , price
            : Natural
        }
    | Median :
        { contract
            : atd.address
        , signers
            : List atd.address
        }
    >

let token =
    { name : Text
    , pipDeploy : PipDeploy
    }

in  { mcdGov : Text
    , mcdFlop: Text
    , mcdFlap: Text
    , DEPLOY_RESTRICTED_FAUCET : Bool
    , proxyRegistry : Optional Text
    }
