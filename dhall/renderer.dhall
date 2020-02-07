let Text/concatMapSep = ./Prelude/Text/concatMapSep

let Text/concatSep = ./Prelude/Text/concatSep

let List/map = ./Prelude/List/map

let schema = ./abiSchema.dhall

let Hex = schema.Hex

let Address = schema.Address

let Void = schema.Void

let Math = schema.Math

let Def = schema.Def

let DefEntry = schema.DefEntry

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

let math
    : Text → Math.Type → Text
    =   λ(op : Text)
      → λ(x : Math.Type)
      → ''
        { "op": "math", "mathOp": "${op}", "x": ${x._math} }
        ''

let math2
    : Text → Math.Type → Math.Type → Text
    =   λ(op : Text)
      → λ(x : Math.Type)
      → λ(y : Math.Type)
      → ''
        { "op": "math", "mathOp": "${op}", "x": ${x._math}, "y": ${y._math} }
        ''

let noop : Natural → Text = λ(id : Natural) → obj "noop" "\"${Natural/show id}\""

let defineMem
    : Natural → Text → Def
    =   λ(id : Natural)
      → λ(code : Text)
      → [
          { mapKey = id
          , mapValue = code
          }
        ]

let callMem
    : Natural → Text → Text → Text
    =   λ(id : Natural)
      → λ(op : Text)
      → λ(type : Text)
      → ''
        { "op": "callDef", "callDef": "${Natural/show id}", "opType": "${op}", "type": ${type} }
        ''

let asciiToHex
    : Text → Hex.Type
    = λ(ascii : Text) → Hex::{ _hex = obj "asciiToHex" "\"${ascii}\"" }

let sig : Text → Hex.Type = λ(t : Text) → Hex::{ _hex = obj "sig" "\"${t}\"" }

let from = Address::{ _address = "{ \"op\": \"from\", \"type\": \"address\" }" }

let num
    =   λ(x : Natural)
      → Math::{ _math = Natural/show x }

let numToHex
    =   λ(scale : Natural)
      → λ(x : Math.Type)
      → Hex::{ _hex = "{ \"op\": \"mathToHex\", \"scale\": ${Natural/show scale}, \"value\": ${x._math} }" }

let add
    =   λ(x : Math.Type)
      → λ(y : Math.Type)
      → Math::{ _math = math2 "add" x y }

let sub
    =   λ(x : Math.Type)
      → λ(y : Math.Type)
      → Math::{ _math = math2 "sub" x y }

let mul
    =   λ(x : Math.Type)
      → λ(y : Math.Type)
      → Math::{ _math = math2 "mul" x y }

let div
    =   λ(x : Math.Type)
      → λ(y : Math.Type)
      → Math::{ _math = math2 "div" x y }

let pow
    =   λ(x : Math.Type)
      → λ(y : Math.Type)
      → Math::{ _math = math2 "pow" x y }

let log
    =   λ(x : Math.Type)
      → Math::{ _math = math "log" x }

let exp
    =   λ(x : Math.Type)
      → Math::{ _math = math "exp" x }

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
      , noop = noop
      , defineMem = defineMem
      , callMem = callMem
      , sig = sig
      , asciiToHex = asciiToHex
      , from = from
      , num = num
      , numToHex = numToHex
      , add = add
      , sub = sub
      , mul = mul
      , div = div
      , pow = pow
      , log = log
      , exp = exp
      , render = toJSON
      }

in  renderer
