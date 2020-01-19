let List/map = ./Prelude/List/map

let Natural/enumerate = ./Prelude/Natural/enumerate

let Conv = (./typesHelper.dhall).Conv

let IntConv =
      { Type = Conv.Type
      , default = Conv::{ type = "Integer", conv = "Integer/show" }
      }

let NatConv =
      { Type = Conv.Type
      , default = Conv::{ type = "Natural", conv = "Natural/show" }
      }

in    [ Conv::{ name = "void" }
      , Conv::{ name = "hex" }
      , Conv::{ name = "address" }
      , Conv::{ name = "bytes" }
      , NatConv::{ name = "uint" }
      , IntConv::{ name = "int" }
      ]
    # List/map
        Natural
        Conv.Type
        (λ(i : Natural) → Conv::{ name = "bytes${Natural/show (i + 1)}" })
        (Natural/enumerate 32)
    # List/map
        Natural
        Conv.Type
        (λ(i : Natural) → NatConv::{ name = "uint${Natural/show (i * 8 + 8)}" })
        (Natural/enumerate 32)
    # List/map
        Natural
        Conv.Type
        (λ(i : Natural) → IntConv::{ name = "int${Natural/show (i * 8 + 8)}" })
        (Natural/enumerate 32)
