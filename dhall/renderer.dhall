let Text/concatMapSep = ./Prelude/Text/concatMapSep

let Text/concatSep = ./Prelude/Text/concatSep

let List/map = ./Prelude/List/map

let schema = ./abiSchema.dhall

let Hex = schema.Hex

let Void = schema.Void

let Def = schema.Def

let DefEntry = schema.DefEntry

let TypeBase = schema.TypeBase

let utils = ./utils.dhall

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

let asciiToHex
    : Text → Hex.Type
    = λ(ascii : Text) → Hex::{ _hex = obj "asciiToHex" "\"${ascii}\"" }

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

let renderer
    : schema.Renderer
    = { concatDefs = concatDefs
      , defineMem = defineMem
      , callMem = callMem
      , sig = sig
      , asciiToHex = asciiToHex
      , render = toJSON
      }

in  renderer
