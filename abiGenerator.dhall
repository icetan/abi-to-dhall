let Text/concatMapSep =
        ./Prelude/Text/concatMapSep
      ? https://prelude.dhall-lang.org/Text/concatMapSep

let Text/concatMap =
        ./Prelude/Text/concatMap
      ? https://prelude.dhall-lang.org/Text/concatMap

let List/map =
        ./Prelude/List/map
      ? https://prelude.dhall-lang.org/List/map

let List/filter =
        ./Prelude/List/filter
      ? https://prelude.dhall-lang.org/List/filter

let schema = ./abiSchema.dhall

let FunArg = schema.FunArg

let SimpleArg = schema.SimpleArg

let ComplexArg = schema.ComplexArg

let SimpleIArg = { index : Natural, value : SimpleArg }

let isConstructor
    : schema.Op → Bool
    =   λ(op : schema.Op)
      → merge
        { Function =
            λ(_ : schema.Fun) → False
        , Fallback =
            λ(_ : schema.Fallback) → False
        , Event =
            λ(_ : schema.Event) → False
        , Constructor =
            λ(_ : schema.Constructor) → True
        }
        op

let hasConstructor
    : List schema.Op → Bool
    =   λ(ops : List schema.Op)
      → Optional/fold
        schema.Op
        (List/head schema.Op (List/filter schema.Op isConstructor ops))
        Bool
        (λ(_ : schema.Op) → True)
        False

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

let funIndexedArgToDhallFun
    : SimpleIArg → Text
    =   λ(iarg : SimpleIArg)
      → "λ(arg${Natural/show
                iarg.index} : { ${iarg.value.type} : Text, def : Text })"

let funArgsToDhallFun
    : List FunArg → Text
    =   λ(args : List FunArg)
      → Text/concatMap
        SimpleIArg
        (λ(arg : SimpleIArg) → " → " ++ funIndexedArgToDhallFun arg)
        (List/indexed SimpleArg (toSimpleArgs args))

let funReturnToDhallType
    : List FunArg → Text
    =   λ(outputs : List FunArg)
      → Optional/fold
        SimpleArg
        (List/head SimpleArg (toSimpleArgs outputs))
        Text
        (λ(arg : SimpleArg) → arg.type)
        "void"

let funSignature
    : List FunArg → Text
    =   λ(args : List FunArg)
      → Text/concatMap
        SimpleArg
        (λ(arg : SimpleArg) → "/${arg.type}")
        (toSimpleArgs args)

let funToDhallName
    : schema.Fun → Text
    = λ(fun : schema.Fun) → "${fun.name}${funSignature fun.inputs}"

let createFun
    : schema.Render → Text → schema.Constructor → Text
    =   λ(render : schema.Render)
      → λ(name : Text)
      → λ(constructor : schema.Constructor)
      → ''
        create${funSignature constructor.inputs} =
            λ(tag : Text)
           ${funArgsToDhallFun constructor.inputs}
            → { address = ${render.createValue constructor}
              , def = ${render.createDef constructor}
              }
        ''

let send
    : schema.Render → schema.Fun → Text
    =   λ(render : schema.Render)
      → λ(fun : schema.Fun)
      → ''
        send/${funToDhallName fun} =
              λ(address : { address : Text, def : Text })${funArgsToDhallFun
                                                           fun.inputs}
            → { void = ${render.sendValue fun}
              , def = ${render.sendDef fun}
              }
        ''

let call
    : schema.Render → schema.Fun → Text
    =   λ(render : schema.Render)
      → λ(fun : schema.Fun)
      → ''
        call/${funToDhallName fun} =
              λ(tag : Text)
            → λ(address : { address : Text, def : Text })${funArgsToDhallFun
                                                           fun.inputs}
            → { ${funReturnToDhallType fun.outputs} = ${render.callValue fun}
           , def = ${render.callDef fun}
              }
        ''

let defaultConstructor =
      schema.Op.Constructor
      { inputs =
          [] : List FunArg
      , payable =
          False
      , stateMutability =
          ""
      , type =
          "constructor"
      }

let abiOpToDhall
    : Text → schema.Render → schema.Op → Text
    =   λ(name : Text)
      → λ(render : schema.Render)
      → λ(op : schema.Op)
      → merge
        { Function =
            λ(fun : schema.Fun) → "${send render fun}\n, ${call render fun}"
        , Fallback =
            λ(fallback : schema.Fallback) → "fallback = {=}"
        , Event =
            λ(event : schema.Event) → "event/${event.name} = {=}"
        , Constructor =
            createFun render name
        }
        op

let abiToDhall
    : Text → schema.Render → schema.Abi → Text
    =   λ(name : Text)
      → λ(render : schema.Render)
      → λ(ops : schema.Abi)
      → ''
        let lib = ../lib/default
        
        let renderLib = ../lib/render
        
        let name = "${name}" 
        
        in  { ${Text/concatMapSep
                ''
                
                , ''
                schema.Op
                (abiOpToDhall name render)
                (   (       if hasConstructor ops
                      
                      then  [] : List schema.Op
                      
                      else  [ defaultConstructor ]
                    )
                  # ops
                )}
            }
        ''

in  abiToDhall
