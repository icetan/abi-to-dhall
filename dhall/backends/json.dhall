let Text/concatMapSep =
        ../Prelude/Text/concatMapSep
      ? https://prelude.dhall-lang.org/Text/concatMapSep

let Text/concatSep =
      ../Prelude/Text/concatSep ? https://prelude.dhall-lang.org/Text/concatSep

let List/map =
        ../Prelude/List/map
      ? https://prelude.dhall-lang.org/List/map

let schema = ../abiSchema.dhall

let util = ./util/json.dhall

let obj : Text → Text → Text = λ(id : Text) → λ(code : Text) → "{ \"${id}\": ${code} }"

let Fun = schema.Fun

let Constructor = schema.Constructor

let FunArg = schema.FunArg

let SimpleArg = schema.SimpleArg

let ComplexArg = schema.ComplexArg

let SimpleIArg = { index : Natural, value : SimpleArg }

let toSimpleArg
    : FunArg → SimpleArg
    =   λ(arg : FunArg)
      → merge
        { Simple =
            λ(arg : SimpleArg) → arg.{ name, type }
        , Complex =
            λ(arg : ComplexArg) → arg.{ name, type }
        }
        arg

let toSimpleArgs
    : List FunArg → List SimpleArg
    = List/map FunArg SimpleArg toSimpleArg

let funIndexedArgToDhallFunValue
    : SimpleIArg → Text
    =   λ(iarg : SimpleIArg)
      → "\${arg${Natural/show iarg.index}.${iarg.value.type}}"

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
      → "(backend.concatDefs ([ ${Text/concatSep
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

let sendValue =
        λ ( fun
          : Fun
          )
      → ''
        ${"''"}
        {
          "op": "send",
          "address": ''${address.address},
          "function": "${fun.name}",
          "argTypes": [ ${funArgsToDhallCall fun.inputs} ],
          "args":     [ ${funArgsToDhallFunValue fun.inputs} ]
        }
        ${"''"}
        ''

let sendDef =
        λ(fun : Fun)
      → funArgNamesToDhallConcatDefs
          ([ "address" ] # funArgsToDhallArgNames fun.inputs)
          ([] : List Text)

let callValue = λ(fun : Fun) → "backend.callMem tag"

let callDef =
        λ ( fun
          : Fun
          )
      → funArgNamesToDhallConcatDefs
          ([ "address" ] # funArgsToDhallArgNames fun.inputs)
          [ ''
            (backend.defineMem tag ${"''"}
            {
              "op": "call",
              "address": ''${address.address},
              "function": "${fun.name}",
              "argTypes": [ ${funArgsToDhallCall fun.inputs} ],
              "args":     [ ${funArgsToDhallFunValue fun.inputs} ],
              "outputTypes":  [ ${funArgsToDhallCall fun.outputs} ]
            }
            ${"''"})''
          ]

let createValue = λ(constructor : Constructor) → "backend.callMem tag"

let createDef =
        λ ( constructor
          : Constructor
          )
      → funArgNamesToDhallConcatDefs
          (funArgsToDhallArgNames constructor.inputs)
          [ ''
            (backend.defineMem tag ${"''"}
            {
              "op": "create",
              "contract": "${"\${name}"}",
              "argTypes": [ ${funArgsToDhallCall constructor.inputs} ],
              "args": [ ${funArgsToDhallFunValue constructor.inputs} ]
            }
            ${"''"})''
          ]

let toOutput
    : Text → Text
    =   λ(val : Text)
      → "{ \\\"op\\\": \\\"output\\\", \\\"id\\\": \\\"\${id}\\\", \\\"value\\\": \${${val}} }"

let toLiteral
    : Text → Text
    =   λ(val : Text)
      → "{ \\\"op\\\": \\\"lit\\\", \\\"value\\\": \\\"\${${val}}\\\" }"

let toListLiteral
    : Text → Text
    =   λ(expr : Text)
      → "[ \${./Prelude/Text/concatMapSep \", \" Text (λ(x : Text) → \"\\\"\${x}\\\"\") (${expr})} ]"

let backend : schema.Backend =
   { util =
        util
    , toOutput =
        toOutput
    , toLiteral =
        toLiteral
    , toListLiteral =
        toListLiteral
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
