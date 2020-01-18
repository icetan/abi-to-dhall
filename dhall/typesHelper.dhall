let Conv =
      { Type = { name : Text, type : Text, conv : Text }
      , default = { name = "void", type = "Text", conv = "λ(x : Text) → x" }
      }

in  { Conv = Conv }
