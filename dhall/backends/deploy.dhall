let Text/concatMapSep =
        ../Prelude/Text/concatMapSep
      ? https://prelude.dhall-lang.org/Text/concatMapSep

let Text/concatSep =
      ../Prelude/Text/concatSep ? https://prelude.dhall-lang.org/Text/concatSep

let List/map = ../Prelude/List/map ? https://prelude.dhall-lang.org/List/map

let schema = ../abiSchema.dhall

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
          { Simple = λ(arg : SimpleArg) → arg.{ name, type }
          , Complex = λ(arg : ComplexArg) → arg.{ name, type }
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
          " "
          SimpleIArg
          funIndexedArgToDhallFunValue
          (List/indexed SimpleArg (toSimpleArgs args))

let funArgsToDhallCall
    : List FunArg → Text
    =   λ(args : List FunArg)
      → Text/concatMapSep
          ","
          SimpleArg
          (λ(arg : SimpleArg) → arg.type)
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

let toOutput : Text → Text = λ(expr : Text) → "echo \\\"\${id}=\${${expr}}\\\""

let toLiteral : Text → Text = λ(expr : Text) → "\${${expr}}"

let toListLiteral
    : Text → Text
    =   λ(expr : Text)
      → "[\${./Prelude/Text/concatSep \",\" (${expr})}]"

let sendValue =
        λ ( fun
          : Fun
          )
      → "\"seth send \${address.address} \\\"${fun.name}(${funArgsToDhallCall
                                                           fun.inputs})\\\" ${funArgsToDhallFunValue
                                                                              fun.inputs}\""

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
          [ "(backend.defineMem tag \"seth call \${address.address} \\\"${fun.name}(${funArgsToDhallCall
                                                                                      fun.inputs})(${funArgsToDhallCall
                                                                                                     fun.outputs})\\\" ${funArgsToDhallFunValue
                                                                                                                         fun.inputs}\")"
          ]

let createValue = λ(constructor : Constructor) → "backend.callMem tag"

let createDef =
        λ ( constructor
          : Constructor
          )
      → funArgNamesToDhallConcatDefs
          (funArgsToDhallArgNames constructor.inputs)
          [ "(backend.defineMem tag \"dapp create \${name} ${funArgsToDhallFunValue
                                                               constructor.inputs}\")"
          ]

let backend
    : schema.Backend
    = { util = ./util/deploy.dhall
      , toOutput = toOutput
      , toLiteral = toLiteral
      , toListLiteral = toListLiteral
      , sendValue = sendValue
      , sendDef = sendDef
      , callValue = callValue
      , callDef = callDef
      , createValue = createValue
      , createDef = createDef
      }

in  backend
