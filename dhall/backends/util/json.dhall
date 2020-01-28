let Text/concatMapSep = ../../Prelude/Text/concatMapSep

let Text/concatSep = ../../Prelude/Text/concatSep

let List/map = ../../Prelude/List/map

let schema = ../../abiSchema.dhall

let Hex = schema.Hex

let Void = schema.Void

let Def = schema.Def

let DefEntry = schema.DefEntry

let TypeBase = schema.TypeBase

let utils = ../../utils.dhall

let concatDefs = utils.concatDefs

let insertSort = utils.insertSort

let def : Void → Def = λ(void : Void) → void.def

let undef
    : Def → List Text
    =   λ(def : Def)
      → List/map
          DefEntry
          Text
          (λ(e : DefEntry) → "{ \"op\": \"def\", \"id\": \"${Natural/show e.mapKey}\", \"def\": ${e.mapValue} }")
          def

let void : Void → Text = λ(void : Void) → void._void

let obj
    : Text → Text → Text
    =   λ(id : Text)
      → λ(code : Text)
      → ''
        { "op": "${id}", "${id}": ${code} }
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
    : Hex.Type → TypeBase ⩓ { _bytes : Text }
    = λ(hex : Hex.Type) → { _bytes = obj "hexToBytes32" hex._hex, def = ([] : Def) } --, size = 32 }

let asciiToHex
    : Text → Hex.Type
    = λ(ascii : Text) → Hex::{ _hex = obj "asciiToHex" "\"${ascii}\"" }

let naturalToUint256
    : Natural → TypeBase ⩓ { _uint : Text }
    = λ(nat : Natural) → { _uint = obj "naturalToUint256" "\"${Natural/show nat}\"", def = ([] : Def) } --, size = 32 }

let integerToInt256
    : Integer → TypeBase ⩓ { _int : Text }
    = λ(int : Integer) → { _int = obj "integerToInt256" "\"${Integer/show int}\"", def = ([] : Def) } --, size = 32 }

let sig : Text → Hex.Type = λ(t : Text) → Hex::{ _hex = obj "sig" "\"${t}\"" }

let toJSON
    : List Void → Text
    =   λ(vs : List Void)
      → ''
        {
          "meta": {
            "generator": "abi-to-dhall"
          },
          "version": 1,
          "ops": [
            ${Text/concatSep
                ",\n"
                ( (undef (insertSort (concatDefs (List/map Void Def def vs))))
                # (List/map Void Text void vs)
                )
            }
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
      , integerToInt256 = integerToInt256
      , render = toJSON
      }

in  renderUtil
