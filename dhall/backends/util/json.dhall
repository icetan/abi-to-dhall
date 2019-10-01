let Text/concatMapSep =
        ../../Prelude/Text/concatMapSep
      ? https://prelude.dhall-lang.org/Text/concatMapSep

let List/map = ../../Prelude/List/map

let schema = ../../abiSchema.dhall

let Hex = schema.Hex

let Void = schema.Void

let Def = schema.Def

let DefEntry = schema.DefEntry

let utils = ../../utils.dhall

let concatDefs = utils.concatDefs

let def : Void → Def = λ(void : Void) → void.def

let undef
    : Def → Text
    =   λ(def : Def)
      → Text/concatMapSep
          ",\n"
          DefEntry
          (λ(e : DefEntry) → "\"${Natural/show e.mapKey}\": ${e.mapValue}")
          def

let void : Void → Text = λ(void : Void) → void.void

let obj
    : Text → Text → Text
    =   λ(id : Text)
      → λ(code : Text)
      → ''
        { "op": "${id}", "val": ${code} }
        ''

let defineMem
    : Natural → Text → Def
    =   λ(id : Natural)
      → λ(code : Text)
      → [
          { mapKey = id
          , mapValue = code
          }
        ]

let callMem : Natural → Text = λ(id : Natural) → obj "callDef" "\"${Natural/show id}\""

let hexToBytes32
    : Hex → { bytes32 : Text, def : Def }
    = λ(hex : Hex) → { bytes32 = obj "hexToBytes32" hex.hex, def = ([] : Def) }

let asciiToHex
    : Text → Hex
    = λ(ascii : Text) → { hex = obj "asciiToHex" "\"${ascii}\"", def = ([] : Def) }

let sig : Text → Hex = λ(t : Text) → { hex = obj "sig" "\"${t}\"", def = ([] : Def) }

let toJSON
    : List Void → Text
    =   λ(vs : List Void)
      → ''
        {
          "defs": {
            ${undef (concatDefs (List/map Void Def def vs))}
          },
          "ast": [
            ${Text/concatMapSep ",\n" Void void vs}
          ]
        }
        ''

let renderUtil
    : schema.BackendUtil
    = { concatDefs = concatDefs
      , defineMem = defineMem
      , callMem = callMem
      , sig = sig
      , hexToBytes32 = hexToBytes32
      , asciiToHex = asciiToHex
      , render = toJSON
      }

in  renderUtil
