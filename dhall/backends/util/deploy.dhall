let Text/concatMapSep =
        ../../Prelude/Text/concatMapSep
      ? https://prelude.dhall-lang.org/Text/concatMapSep

let List/map = ../../Prelude/List/map

let List/any = ../../Prelude/List/any

let Natural/equal = ../../Prelude/Natural/equal

let schema = ../../abiSchema.dhall

let Hex = schema.Hex

let Void = schema.Void

let Def = schema.Def

let DefEntry = { mapKey : Natural, mapValue : Text }

let def : Void → Def = λ(void : Void) → void.def

let undef
    : Def → Text
    =   λ(def : Def)
      → List/fold
          DefEntry
          def
          Text
          (   λ(e : DefEntry)
            → λ(acc : Text)
            → acc ++ e.mapValue
          )
          ""

let void : Void → Text = λ(void : Void) → void.void

let eval : Text → Text = λ(code : Text) → "\$(${code})"

let defineMem
    : Natural → Text → Def
    =   λ ( id
          : Natural
          )
      → λ(code : Text)
      → [
          { mapKey = id
          , mapValue = "_mem_${Natural/show id}() { _val_${Natural/show id}=\${_val_${Natural/show id}-${eval code}}; printf %s \"\$_val_${Natural/show id}\"; }\n"
          }
        ]

let callMem : Natural → Text = λ(id : Natural) → eval "_mem_${Natural/show id}"

let concatDef
    : Def → Def → Def
    =   λ(x : Def)
      → λ(acc : Def)
      → List/fold
          DefEntry
          x
          Def
          (   λ(e : DefEntry)
            → λ(acc : Def)
            →       if List/any DefEntry (λ(n : DefEntry) → Natural/equal n.mapKey e.mapKey) acc
              then  acc
              else  acc # [ e ]
          )
          acc

let concatDefs
    : List Def → Def
    =   λ(defs : List Def)
      → List/fold
          Def
          defs
          Def
          concatDef
          ([] : Def)

let hexToBytes32
    : Hex → { bytes32 : Text, def : Def }
    =   λ(hex : Hex)
      → { bytes32 = eval "seth --to-bytes32 ${hex.hex}", def = ([] : Def) }

let asciiToHex
    : Text → Hex
    =   λ(ascii : Text)
      → { hex = eval "seth --from-ascii \"${ascii}\"", def = ([] : Def) }

let sig
    : Text → Hex
    = λ(t : Text) → { hex = eval "seth sig \"${t}\"", def = ([] : Def) }

let toBash
    : List Void → Text
    =   λ(vs : List Void)
      → ''
        #!/usr/bin/env bash
        set -ex
        
        # Definitions
        ${undef (concatDefs (List/map Void Def def vs))}
        
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
