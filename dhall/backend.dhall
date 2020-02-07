let Text/concatMapSep = ./Prelude/Text/concatMapSep

let Text/concatSep = ./Prelude/Text/concatSep

let List/map = ./Prelude/List/map

let schema = ./abiSchema.dhall

let obj : Text → Text → Text = λ(id : Text) → λ(code : Text) → "{ \"${id}\": ${code} }"

let Fun = schema.Fun

let Constructor = schema.Constructor

let FunArg = schema.FunArg

let SimpleArg = schema.SimpleArg

let SimpleArgV2 = schema.SimpleArgV2

let ComplexArg = schema.ComplexArg

let ComplexArgV2 = schema.ComplexArgV2

let SimpleIArg = { index : Natural, value : SimpleArg }

let toSimpleArg
    : FunArg → SimpleArg
    =   λ(arg : FunArg)
      → merge
        { Simple =
            λ(arg : SimpleArg) → arg.{ name, type }
        , SimpleV2 =
            λ(arg : SimpleArgV2) → arg.{ name, type }
        , Complex =
            λ(arg : ComplexArg) → arg.{ name, type }
        , ComplexV2 =
            λ(arg : ComplexArgV2) → arg.{ name, type }
        }
        arg

let toSimpleArgs
    : List FunArg → List SimpleArg
    = List/map FunArg SimpleArg toSimpleArg

let funIndexedArgToDhallFunValue
    : SimpleIArg → Text
    =   λ(iarg : SimpleIArg)
      → "\${types.evm/${iarg.value.type}/value arg${Natural/show iarg.index}}"

let funArgsToDhallFunValue
    : List FunArg → Text
    =   λ(args : List FunArg)
      → Text/concatMapSep
        ", "
        SimpleIArg
        funIndexedArgToDhallFunValue
        (List/indexed SimpleArg (toSimpleArgs args))

let funArgsToDhallCall
    : List FunArg → Text
    =   λ(args : List FunArg)
      → Text/concatMapSep
        ", "
        SimpleArg
        (λ(arg : SimpleArg) → "\"${arg.type}\"")
        (toSimpleArgs args)

let funArgNamesToDhallConcatDefs
    : List Text → List Text → Text
    =   λ(names : List Text)
      → λ(extra : List Text)
      → "(renderer.concatDefs ([ ${Text/concatSep
                                    ", "
                                    (   List/map
                                          Text
                                          Text
                                          (λ(name : Text) → "${name}.def")
                                          names
                                      # extra
                                    )} ] : List Def))"

let funArgsToDhallArgNames
    : List FunArg → List Text
    =   λ(args : List FunArg)
      → List/map
        SimpleIArg
        Text
        (λ(iarg : SimpleIArg) → "arg${Natural/show iarg.index}")
        (List/indexed SimpleArg (toSimpleArgs args))

--let sendValue =
--        λ ( fun
--          : Fun
--          )
--      → ''
--        ${"''"}
--        {
--          "op": "send",
--          "address": ''${address._address},
--          "prefix": "''${prefix}",
--          "contract": "''${name}",
--          "function": "${fun.name}",
--          "argTypes": [ ${funArgsToDhallCall fun.inputs} ],
--          "args":     [ ${funArgsToDhallFunValue fun.inputs} ]
--        }
--        ${"''"}
--        ''
let sendValue = λ(fun : Fun) → "renderer.noop tag"

--let sendDef =
--        λ(fun : Fun)
--      → funArgNamesToDhallConcatDefs
--          ([ "address" ] # funArgsToDhallArgNames fun.inputs)
--          ([] : List Text)
let sendDef =
        λ ( fun
          : Fun
          )
      → funArgNamesToDhallConcatDefs
          ([ "address" ] # funArgsToDhallArgNames fun.inputs)
          [ ''
            (renderer.defineMem tag ${"''"}
            {
              "op": "send",
              "address": ''${address._address},
              "prefix": "''${prefix}",
              "contract": "''${name}",
              "function": "${fun.name}",
              "argTypes": [ ${funArgsToDhallCall fun.inputs} ],
              "args":     [ ${funArgsToDhallFunValue fun.inputs} ]
            }
            ${"''"})''
          ]

let callValue = λ(fun : Fun) → "renderer.callMem tag \"call\" ''\n[ ${funArgsToDhallCall fun.outputs} ]''"

let callDef =
        λ ( fun
          : Fun
          )
      → funArgNamesToDhallConcatDefs
          ([ "address" ] # funArgsToDhallArgNames fun.inputs)
          [ ''
            (renderer.defineMem tag ${"''"}
            {
              "op": "call",
              "address": ''${address._address},
              "prefix": "''${prefix}",
              "contract": "''${name}",
              "function": "${fun.name}",
              "argTypes": [ ${funArgsToDhallCall fun.inputs} ],
              "args":     [ ${funArgsToDhallFunValue fun.inputs} ],
              "outputTypes":  [ ${funArgsToDhallCall fun.outputs} ]
            }
            ${"''"})''
          ]

let createValue = λ(constructor : Constructor) → "renderer.callMem tag \"create\" \"\\\"address\\\"\" "

let createDef =
        λ ( constructor
          : Constructor
          )
      → funArgNamesToDhallConcatDefs
          (funArgsToDhallArgNames constructor.inputs)
          [ ''
            (renderer.defineMem tag ${"''"}
            {
              "op": "create",
              "prefix": "''${prefix}",
              "contract": "''${name}",
              "argTypes": [ ${funArgsToDhallCall constructor.inputs} ],
              "args": [ ${funArgsToDhallFunValue constructor.inputs} ]
            }
            ${"''"})''
          ]

let toOutput
    : Text → Text → Text
    =   λ(type : Text)
      → λ(expr : Text)
      → "{ \\\"op\\\": \\\"output\\\", \\\"id\\\": \\\"\${id}\\\", \\\"value\\\": \${${expr}}, \\\"type\\\": \\\"${type}\\\" }"

let toLiteral
    : Text → Text → Text
    =   λ(type : Text)
      → λ(expr : Text)
      → "{ \\\"op\\\": \\\"lit\\\", \\\"value\\\": \\\"\${${expr}}\\\", \\\"type\\\": \\\"${type}\\\" }"

let toListLiteral
    : Text → Text → Text
    =   λ(type : Text)
      → λ(expr : Text)
      → "{ \\\"op\\\": \\\"lit\\\", \\\"value\\\": [ \${./Prelude/Text/concatMapSep \", \" Text (λ(x : Text) → \"\\\"\${x}\\\"\") (${expr})} ], \\\"type\\\": \\\"${type}\\\" }"

let toHex
    : Text → Text → Text
    =   λ(type : Text)
      → λ(expr : Text)
      → "{ \\\"op\\\": \\\"toHex\\\", \\\"type\\\": \\\"${type}\\\", \\\"value\\\": \${${expr}} }"

let fromHex
    : Text → Text → Text
    =   λ(type : Text)
      → λ(expr : Text)
      → "{ \\\"op\\\": \\\"fromHex\\\", \\\"type\\\": \\\"${type}\\\", \\\"value\\\": \${${expr}} }"

let backend : schema.Backend =
   { toOutput =
        toOutput
    , toLiteral =
        toLiteral
    , toListLiteral =
        toListLiteral
    , toHex =
        toHex
    , fromHex =
        fromHex
    , sendValue =
        sendValue
    , sendDef =
        sendDef
    , callValue =
        callValue
    , callDef =
        callDef
    , createValue =
        createValue
    , createDef =
        createDef
    }

in backend
