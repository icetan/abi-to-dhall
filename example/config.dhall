let atd = ./atd/package

in  { mint = atd.ethToWei 1000000
    , auctionAddress =
        atd.Address/build "0x0000000000000000000000000000000000000001"
    }
