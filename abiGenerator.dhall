let Text/concatMapSep =
        ~/src/dhall-lang/Prelude/Text/concatMapSep
      ? https://prelude.dhall-lang.org/Text/concatMapSep

let Text/concatMap =
        ~/src/dhall-lang/Prelude/Text/concatMap
      ? https://prelude.dhall-lang.org/Text/concatMap

let List/map =
        ~/src/dhall-lang/Prelude/List/map
      ? https://prelude.dhall-lang.org/List/map

let List/filter =
        ~/src/dhall-lang/Prelude/List/filter
      ? https://prelude.dhall-lang.org/List/filter

let lib = ./lib.dhall

let schema = ./abiSchema.dhall

let FunArg = schema.FunArg

let SimpleArg = schema.SimpleArg

let ComplexArg = schema.ComplexArg

let FunIArg = { index : Natural, value : FunArg }

let SimpleIArg = { index : Natural, value : SimpleArg }

let isConstructor
    : schema.Op → Bool
    = λ(op : schema.Op)
      → merge
        { Function = λ(_ : schema.Fun) → False
        , Fallback = λ(_ : schema.Fallback) → False
        , Event = λ(_ : schema.Event) → False
        , Constructor = λ(_ : schema.Constructor) → True
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
        { Simple = λ(arg : SimpleArg) → arg.{ name, type }
        , Complex = λ(arg : ComplexArg) → arg.{ name, type }
        }
        arg

let toSimpleArgs
    : List FunArg → List SimpleArg
    = List/map FunArg SimpleArg toSimpleArg

let staticTypeToDhallType
    : SimpleArg → Text
    = λ(arg : SimpleArg) → "{ ${arg.type} : Text, def : Text }"

let simpleArgToDhallType
    : SimpleArg → Text
    = λ(arg : SimpleArg) → "${arg.name} : ${staticTypeToDhallType arg}"

--let simpleIndexedArgToDhallFun
--    : SimpleIArg → Text
--    =   λ(iarg : SimpleIArg)
--      → "λ(arg${Natural/show iarg.index} : { ${iarg.value.type} : Text, def : Text })"
--
--let complexArgToDhallFun
--    : List SimpleArg → Text
--    =   λ(args : List SimpleIArg)
--      → Text/concatMapSep
--        "\n→ "
--        SimpleIArg
--        simpleIndexedArgToDhallFun
--        (List/indexed SimpleIArg args)

-- let complexArgToDhallType
--     : ComplexArg → Text
--     = λ(arg : ComplexArg) → "${arg.name} : (${complexArgToDhallFun arg.components})"

let complexArgToDhallType
    : ComplexArg → Text
    = λ(arg : ComplexArg) → simpleArgToDhallType arg.{ name, type }

let funArgToDhallType
    : FunArg → Text
    = λ(arg : FunArg)
      → merge
        { Simple = simpleArgToDhallType
        , Complex = complexArgToDhallType
        }
        arg

let funArgsToDhallType
    : List FunArg → Text
    =   λ(args : List FunArg)
      → "{ ${Text/concatMapSep ", " SimpleArg simpleArgToDhallType (toSimpleArgs args)} }"

let funIndexedArgToDhallFunValue
    : SimpleIArg → Text
    = λ(iarg : SimpleIArg) → "\${arg${Natural/show iarg.index}.${iarg.value.type}}"

let funArgsToDhallFunValue
    : List FunArg → Text
    =   λ(args : List FunArg)
      → Text/concatMapSep
        " "
        SimpleIArg
        funIndexedArgToDhallFunValue
        (List/indexed SimpleArg (toSimpleArgs args))

let funIndexedArgToDhallFun
    : SimpleIArg → Text
    =   λ(iarg : SimpleIArg)
      → "λ(arg${Natural/show iarg.index} : { ${iarg.value.type} : Text, def : Text })"

let funArgsToDhallFun
    : List FunArg → Text
    =   λ(args : List FunArg)
      → Text/concatMap
        SimpleIArg
        (λ(arg :  SimpleIArg) → " → " ++ (funIndexedArgToDhallFun arg))
        (List/indexed SimpleArg (toSimpleArgs args))

let funArgsToDhallArgNames
    : List FunArg → List Text
    =   λ(args : List FunArg)
      → List/map
        SimpleIArg
        Text
        (λ(iarg : SimpleIArg) → "arg${Natural/show iarg.index}")
        (List/indexed SimpleArg (toSimpleArgs args))

let funArgNamesToDhallConcatDefs
    : List Text → Text
    =   λ(names : List Text)
      → "(lib.concatDefs ([ ${Text/concatMapSep
                              ", "
                              Text
                              (λ(name : Text) → "${name}.def")
                              names} ] : List Text))"

let funArgToDhallCreate
    : Text → SimpleArg → Text
    =   λ(vname : Text)
      → λ(arg : SimpleArg)
      → "\${${vname}.${arg.name}.${arg.type}}"

let funArgsToDhallCreate
    : Text → List FunArg → Text
    =   λ(vname : Text)
      → λ(args : List FunArg)
      → Text/concatMapSep " " SimpleArg (funArgToDhallCreate vname) (toSimpleArgs args)

let funArgsToDhallCall
    : List FunArg → Text
    =   λ(args : List FunArg)
      → Text/concatMapSep "," SimpleArg (λ(arg : SimpleArg) → arg.type) (toSimpleArgs args)

let funReturnToDhallType
    : List FunArg → Text
    =   λ(outputs : List FunArg)
      → Optional/fold
        SimpleArg
        (List/head SimpleArg (toSimpleArgs outputs))
        Text
        (λ(arg : SimpleArg) → arg.type)
        "void"

-- let funArity
--     : ∀(a : Type) → List a → Text
--     = λ(a : Type) → λ(ls : List a) → Natural/show (List/length a ls)

let funSignature
    : List FunArg → Text
    =   λ(args : List FunArg)
      → Text/concatMap SimpleArg (λ(arg : SimpleArg) → "/${arg.type}") (toSimpleArgs args)

-- let optText
--     : ∀(a : Type) → List a → Text → Text
--     =   λ(a : Type)
--       → λ(ls : List a)
--       → λ(t : Text)
--       → Optional/fold a (List/head a ls) Text (λ(_ : a) → t) ""

let funToDhallName
    : schema.Fun → Text
    = λ(fun : schema.Fun) → "${fun.name}${funSignature fun.inputs}"

let create
    : Text → schema.Constructor → Text
    =   λ ( name
          : Text
          )
      → λ(constructor : schema.Constructor)
      → ''
        create${funSignature constructor.inputs} =
              λ(tag : Text)
            → λ(args : ${funArgsToDhallType constructor.inputs})
            → { address = lib.callMem tag
              , def = lib.defineMem tag "dapp create ${name} ${funArgsToDhallCreate
                                                                     "args"
                                                                     constructor.inputs}\necho ''${tag}=$''${tag}"
              }
        ''

let createFun
    : Text → schema.Constructor → Text
    =   λ ( name
          : Text
          )
      → λ(constructor : schema.Constructor)
      → ''
        create${funSignature constructor.inputs} =
              λ(tag : Text)
           ${funArgsToDhallFun constructor.inputs}
            → { address =
                  lib.callMem tag
              , def =
                      ${funArgNamesToDhallConcatDefs (funArgsToDhallArgNames constructor.inputs)}
                  ++  (lib.defineMem tag "dapp create ${name} ${funArgsToDhallFunValue
                                                                constructor.inputs}")
              }
        ''

let send
    : schema.Fun → Text
    =   λ ( fun
          : schema.Fun
          )
      → ''
        send/${funToDhallName fun} =
              λ(address : { address : Text, def : Text })${funArgsToDhallFun fun.inputs}
            → { void = "seth send ''${address.address} ${fun.name}(${funArgsToDhallCall
                                                                     fun.inputs}) ${funArgsToDhallFunValue
                                                                                    fun.inputs}"
              , def = ${funArgNamesToDhallConcatDefs (funArgsToDhallArgNames fun.inputs)}
              }
        ''

let call
    : schema.Fun → Text
    =   λ ( fun
          : schema.Fun
          )
      → ''
        call/${funToDhallName fun} =
              λ(tag : Text)
            → λ(address : { address : Text, def : Text })${funArgsToDhallFun fun.inputs}
            → { ${funReturnToDhallType fun.outputs} =
                  lib.callMem tag
              , def =
                      ${funArgNamesToDhallConcatDefs ([ "address" ] # (funArgsToDhallArgNames fun.inputs))}
                  ++  (lib.defineMem tag "seth call ''${address.address} ${fun.name}(${funArgsToDhallCall
                                                                                       fun.inputs})(${funArgsToDhallCall
                                                                                                      fun.outputs}) ${funArgsToDhallFunValue
                                                                                                                      fun.inputs}")
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
    : Text → schema.Op → Text
    =   λ(name : Text)
      → λ(op : schema.Op)
      → merge
        { Function =
            λ(fun : schema.Fun) → "${send fun}\n, ${call fun}"
        , Fallback =
            λ(fallback : schema.Fallback) → "fallback = {=}"
        , Event =
            λ(event : schema.Event) → "event/${event.name} = {=}"
        , Constructor =
            createFun name
        }
        op

let abiToDhall
    : Text → schema.Abi → Text
    =   λ(name : Text)
      → λ(ops : schema.Abi)
      → ''
        let lib = ./lib.dhall
        
        in
        { ${Text/concatMapSep
                ''
                
                , ''
                schema.Op
                (abiOpToDhall name)
                ((if (hasConstructor ops) then ([] : List schema.Op) else [defaultConstructor]) # ops)}
            }
        ''

in  abiToDhall
