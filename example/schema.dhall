let atd = ./atd/package

let State =
      { tokenAddress : Optional atd.Address
      , guardAddress : Optional atd.Address
      }

let Config = { mint : Natural, auctionAddress : atd.Address }

in  { Config = Config, State = State }
