let Text/concatMapSep = ~/src/dhall-lang/Prelude/Text/concatMapSep

let Text/concatSep = ~/src/dhall-lang/Prelude/Text/concatSep

let Text/concatMap = ~/src/dhall-lang/Prelude/Text/concatMap

let Void : Type = { void : Text, def : Text }

let defs : Void → Text = λ(void : Void) → void.def

let void : Void → Text = λ(void : Void) → void.void

let ethToWei : Natural → Natural = λ(eth : Natural) → eth * 1000000000000000000

let ethToGWei : Natural → Natural = λ(eth : Natural) → eth * 1000000000

let toUint256
    : Natural → { uint256 : Text, def : Text }
    = λ(nat : Natural) → { uint256 = Natural/show nat, def = "" }

let optionalVoid
    : Optional Void → Void
    =   λ(v : Optional Void)
      → Optional/fold Void v Void (λ(v : Void) → v) { void = "", def = "" }

in  { ethToWei =
        ethToWei
    , ethToGWei =
        ethToGWei
    , toUint256 =
        toUint256
    , optionalVoid =
        optionalVoid
    --, emptyVoid =
    --    { void = "", def = "" }
    }
