let Text/concatMapSep = ~/src/dhall-lang/Prelude/Text/concatMapSep

let Text/concatSep = ~/src/dhall-lang/Prelude/Text/concatSep

let Text/concatMap = ~/src/dhall-lang/Prelude/Text/concatMap

let Hex : Type = { hex : Text, def : Text }

let Void : Type = { void : Text, def : Text }

let eval : Text → Text = λ(code : Text) → "\$(${code})"

let tag
    : Optional Text → Text → Text
    =   λ(tag : Optional Text)
      → λ(code : Text)
      → eval
        ( Optional/fold
          Text
          tag
          Text
          (λ(t : Text) → "${t}=\${${t}-\$(${code})}; printf %s \"\$${t}\"")
          code
        )

let defineMem
    : Text → Text → Text
    =   λ ( id
          : Text
          )
      → λ(code : Text)
      → ''
        _mem_${id}() { _val_${id}=''${_val_${id}-${eval
                                                   code}}; printf %s "$_val_${id}"; }
        ''

let callMem : Text → Text = λ(id : Text) → eval "_mem_${id}"

let bytes32FromHex
    : Hex → { bytes32 : Text, def : Text }
    = λ(hex : Hex) → { bytes32 = eval "seth --to-bytes32 ${hex.hex}", def = "" }

let asciiToHex
    : Text → Hex
    =   λ(ascii : Text)
      → { hex = eval "seth --from-ascii \"${ascii}\"", def = "" }

let ethToWei : Natural → Natural = λ(eth : Natural) → eth * 1000000000000000000

let ethToGWei : Natural → Natural = λ(eth : Natural) → eth * 1000000000

let toUint256
    : Natural → { uint256 : Text, def : Text }
    = λ(nat : Natural) → { uint256 = Natural/show nat, def = "" }

let addressToVoid
    : { address : Text, def : Text } → Void
    =   λ(address : { address : Text, def : Text })
      → { void = "printf %s \"${address.address}\"", def = address.def }

let sig : Text → Hex = λ(t : Text) → { hex = eval "seth sig '${t}'", def = "" }

let defs : Void → Text = λ(void : Void) → void.def

let void : Void → Text = λ(void : Void) → void.void

let optionalVoid
    : Optional Void → Void
    =   λ(v : Optional Void)
      → Optional/fold Void v Void (λ(v : Void) → v) { void = "", def = "" }

let concatDefs : List Text → Text = Text/concatMap Text (λ(def : Text) → def)

let calls : Void → Text = λ(void : Void) → void.void

let toBash
    : List Void → Text
    =   λ(vs : List Void)
      → ''
        #!/usr/bin/env bash
        set -ex
        
        # Definitions
        ${Text/concatMap Void defs vs}
        
        # Executions
        ${Text/concatMapSep "\n" Void void vs}
        ''

in  { bytes32FromHex =
        bytes32FromHex
    , asciiToHex =
        asciiToHex
    , ethToWei =
        ethToWei
    , ethToGWei =
        ethToGWei
    , toUint256 =
        toUint256
    , addressToVoid =
        addressToVoid
    , optionalVoid =
        optionalVoid
    , emptyVoid =
        { void = "", def = "" }
    , sig =
        sig
    , eval =
        eval
    , concatDefs =
        concatDefs
    , defineMem =
        defineMem
    , callMem =
        callMem
    , toBash =
        toBash
    }
