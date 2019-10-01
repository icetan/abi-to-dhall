let Void : Type = { void : Text, def : Optional Text }

let ethToWei : Natural → Natural = λ(eth : Natural) → eth * 1000000000000000000

let ethToGWei : Natural → Natural = λ(eth : Natural) → eth * 1000000000

let toUint256
    : Natural → { uint256 : Text, def : Optional Text }
    = λ(nat : Natural) → { uint256 = Natural/show nat, def = None Text }

let optionalVoid
    : Optional Void → Void
    =   λ(v : Optional Void)
      → Optional/fold Void v Void (λ(v : Void) → v) { void = "", def = None Text }

in  { ethToWei = ethToWei
    , ethToGWei = ethToGWei
    , toUint256 = toUint256
    , optionalVoid = optionalVoid
    }
