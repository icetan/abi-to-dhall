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

let insertSort = utils.insertSort

let def : Void → Def = λ(void : Void) → void.def

let undef
    : Def → Text
    =   λ(def : Def)
      → Text/concatMapSep
          ",\n"
          DefEntry
          (λ(e : DefEntry) → "{ \"id\": \"${Natural/show e.mapKey}\", \"def\": ${e.mapValue} }")
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

let callMem : Natural → Text = λ(id : Natural) → obj "callDef" "{ \"defId\" : \"${Natural/show id}\" }"

let hexToBytes32
    : Hex → { bytes32 : Text, def : Def }
    = λ(hex : Hex) → { bytes32 = obj "hexToBytes32" hex.hex, def = ([] : Def) }

let asciiToHex
    : Text → Hex
    = λ(ascii : Text) → { hex = obj "asciiToHex" "\"${ascii}\"", def = ([] : Def) }

let naturalToUint256
    : Natural → { uint256 : Text, def : Def }
    = λ(nat : Natural) → { uint256 = obj "naturalToUint256" "\"${Natural/show nat}\"", def = ([] : Def) }

let sig : Text → Hex = λ(t : Text) → { hex = obj "sig" "\"${t}\"", def = ([] : Def) }

let toJSON
    : List Void → Text
    =   λ(vs : List Void)
      → ''
        {
          "defs": [
            ${undef (insertSort (concatDefs (List/map Void Def def vs)))}
          ],
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
      , naturalToUint256 = naturalToUint256
      , render = toJSON
      }

in  renderUtil
