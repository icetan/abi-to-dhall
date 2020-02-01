let atd = ./atd/package

in  { Input = { tokenAddress : Optional Text, guardAddress : Optional Text }
    , Output = { tokenAddress : atd.Address, guardAddress : atd.Address }
    , Config = { mint : Natural, auctionAddress : Text }
    }
