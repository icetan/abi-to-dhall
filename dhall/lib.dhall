let Text/concatMapSep =
        ./Prelude/Text/concatMapSep
      ? https://prelude.dhall-lang.org/Text/concatMapSep

let Text/concatMap =
        ./Prelude/Text/concatMap
      ? https://prelude.dhall-lang.org/Text/concatMap

let Text/concatSep =
        ./Prelude/Text/concatSep
      ? https://prelude.dhall-lang.org/Text/concatSep

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
