let List/map = ./Prelude/List/map

let Natural/enumerate = ./Prelude/Natural/enumerate

let Conv = (./typesHelper.dhall).Conv

let IntConv =
      { Type = Conv.Type
      , default = Conv::{
        , name = "Int"
        , group = "int256"
        , evm = "int"
        --, size = 32
        , type = "Integer"
        , conv = "Integer/show"
        }
      }

let NatConv =
      { Type = Conv.Type
      , default = Conv::{
        , name = "Uint"
        , group = "uint256"
        , evm = "uint"
        --, size = 32
        , type = "Natural"
        , conv = "Natural/show"
        }
      }

let ByteConv =
      { Type = Conv.Type
      , default = Conv::{
        , name = "Bytes"
        , group = "bytes1"
        , evm = "bytes"
        --, size = 1
        }
      }

let AddrConv =
      { Type = Conv.Type
      , default = Conv::{
        , name = "Address"
        , group = "address"
        , evm = "address"
        --, size = 20
        }
      }

in    [ Conv.default
      , Conv::{
          name = "Hex"
        , group = "hex"
        , evm = "hex"
        }
      , Conv::{
          name = "Boolean"
        , group = "bool"
        , evm = "bool"
        , type = "Bool"
        , conv = "λ(b : Bool) → if b then \"true\" else \"false\""
        }
      , AddrConv.default
      , ByteConv.default
      , NatConv.default
      , IntConv.default
      , Conv::{
          name = "String"
        , group = "string"
        , evm = "string"
        }
      , Conv::{
          name = "Tuple"
        , group = "tuple"
        , evm = "tuple"
        }
      ]
    # List/map
        Natural
        Conv.Type
        (   λ(i : Natural)
          → let suf = Natural/show (i + 1)

            in  ByteConv::{
                , name = "Bytes${suf}"
                , group = "bytes${suf}"
                , evm = "bytes${suf}"
                --, size = i + 1
                }
        )
        (Natural/enumerate 32)
    # List/map
        Natural
        Conv.Type
        (   λ(i : Natural)
          → let suf = Natural/show (i * 8 + 8)

            in  NatConv::{
                , name = "Uint${suf}"
                , group = "uint${suf}"
                , evm = "uint${suf}"
                --, size = i + 1
                }
        )
        (Natural/enumerate 32)
    # List/map
        Natural
        Conv.Type
        (   λ(i : Natural)
          → let suf = Natural/show (i * 8 + 8)

            in  IntConv::{
                , name = "Int${suf}"
                , group = "int${suf}"
                , evm = "int${suf}"
                --, size = i + 1 }
                }
        )
        (Natural/enumerate 32)
