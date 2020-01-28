let Conv =
      { Type =
          { name : Text
          , group : Text
          , evm : Text
          --, size : Natural
          , type : Text
          , conv : Text
          }
      , default =
          { name = "Void"
          , group = "void"
          , evm = "void"
          --, size = 0
          , type = "Text"
          , conv = "λ(x : Text) → x"
          }
      }

in  { Conv = Conv }
