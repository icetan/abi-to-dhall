let atd = ../atd/package

in  { Import = { tokenAddress : Optional Text, guardAddress : Optional Text }
    , Config = { mint : Natural, auctionAddress : Text }
    , Output = { tokenAddress : atd.Address, guardAddress : atd.Address }
    }
