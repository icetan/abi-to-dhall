let Text/concatMapSep =
        ../../Prelude/Text/concatMapSep
      ? https://prelude.dhall-lang.org/Text/concatMapSep

let List/filter = ../../Prelude/List/filter

let List/map = ../../Prelude/List/map

let Bool/not = ../../Prelude/Bool/not

let Optional/null = ../../Prelude/Optional/null

let schema = ../../abiSchema.dhall

let Hex = schema.Hex

let Void = schema.Void

let def : Void → Optional Text = λ(void : Void) → void.def

let undef
    : Optional Text → Text
    =   λ(ot : Optional Text)
      → Optional/fold
          Text
          ot
          Text
          (λ(t : Text) → t)
          "echo >&2 THIS SHOULDN'T HAPPEN"

let void : Void → Text = λ(void : Void) → void.void

let eval : Text → Text = λ(code : Text) → "\$(${code})"

let defineMem
    : Text → Text → Optional Text
    =   λ ( id
          : Text
          )
      → λ(code : Text)
      → Some
        "_mem_${id}() { _val_${id}=\${_val_${id}-${eval
                                                     code}}; printf %s \"\$_val_${id}\"; }\n"

let callMem : Text → Text = λ(id : Text) → eval "_mem_${id}"

let concatDefs
    : List (Optional Text) → Optional Text
    =   λ(defs : List (Optional Text))
      → List/fold
          (Optional Text)
          ( List/filter
              (Optional Text)
              (λ(ot : Optional Text) → Bool/not (Optional/null Text ot))
              defs
          )
          (Optional Text)
          (   λ(x : Optional Text)
            → λ(y : Optional Text)
            →       if Optional/null Text y
              
              then  if Optional/null Text x then None Text else Some (undef x)
              
              else  Some (undef x ++ undef y)
          )
          (None Text)

let hexToBytes32
    : Hex → { bytes32 : Text, def : Optional Text }
    =   λ(hex : Hex)
      → { bytes32 = eval "seth --to-bytes32 ${hex.hex}", def = None Text }

let asciiToHex
    : Text → Hex
    =   λ(ascii : Text)
      → { hex = eval "seth --from-ascii \"${ascii}\"", def = None Text }

let sig
    : Text → Hex
    = λ(t : Text) → { hex = eval "seth sig \"${t}\"", def = None Text }

let toBash
    : List Void → Text
    =   λ(vs : List Void)
      → ''
        #!/usr/bin/env bash
        set -ex
        
        # Definitions
        ${undef (concatDefs (List/map Void (Optional Text) def vs))}
        
        # Executions
        ${Text/concatMapSep "\n" Void void vs}
        ''

let renderUtil
    : schema.BackendUtil
    = { concatDefs = concatDefs
      , defineMem = defineMem
      , callMem = callMem
      , sig = sig
      , hexToBytes32 = hexToBytes32
      , asciiToHex = asciiToHex
      , render = toBash
      }

in  renderUtil
