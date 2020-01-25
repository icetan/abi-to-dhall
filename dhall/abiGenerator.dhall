let Text/concatMapSep =
        ./Prelude/Text/concatMapSep
      ? https://prelude.dhall-lang.org/Text/concatMapSep

let Text/concatMap =
      ./Prelude/Text/concatMap ? https://prelude.dhall-lang.org/Text/concatMap

let Text/concatSep =
      ./Prelude/Text/concatSep ? https://prelude.dhall-lang.org/Text/concatSep

let List/map = ./Prelude/List/map ? https://prelude.dhall-lang.org/List/map

let List/filter =
      ./Prelude/List/filter ? https://prelude.dhall-lang.org/List/filter

let schema = ./abiSchema.dhall

let Def = schema.Def

let FunArg = schema.FunArg

let SimpleArg = schema.SimpleArg

let SimpleArgV2 = schema.SimpleArgV2

let ComplexArg = schema.ComplexArg

let ComplexArgV2 = schema.ComplexArgV2

let SimpleIArg = { index : Natural, value : SimpleArg }

let isConstructor
    : schema.Op → Bool
    =   λ(op : schema.Op)
      → merge
          { Function = λ(_ : schema.Fun) → False
          , Fallback = λ(_ : schema.Fallback) → False
          , Event = λ(_ : schema.Event) → False
          , Constructor = λ(_ : schema.Constructor) → True
          }
          op

let isntConstructor
    : schema.Op → Bool
    =   λ(op : schema.Op)
      → (isConstructor op) == False

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
          , SimpleV2 = λ(arg : SimpleArgV2) → arg.{ name, type }
          , Complex = λ(arg : ComplexArg) → arg.{ name, type }
          , ComplexV2 = λ(arg : ComplexArgV2) → arg.{ name, type }
          }
          arg

let toSimpleArgs
    : List FunArg → List SimpleArg
    = List/map FunArg SimpleArg toSimpleArg

let funIndexedArgToDhallFun
    : SimpleIArg → Text
    =   λ(iarg : SimpleIArg)
      → "(arg${Natural/show
                  iarg.index} : { ${iarg.value.type} : Text, def : Def })"

let funArgsToDhallFun
    : Text → List FunArg → Text
    =   λ(prfx : Text)
      → λ(args : List FunArg)
      → Text/concatMap
          SimpleIArg
          (λ(arg : SimpleIArg) → prfx ++ (funIndexedArgToDhallFun arg) ++ " → ")
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

let funArgsSignature
    : List FunArg → Text
    =   λ(args : List FunArg)
      → Text/concatMapSep
          "-"
          SimpleArg
          (λ(arg : SimpleArg) → arg.type)
          (toSimpleArgs args)

let funSignature
    : List Text → List FunArg → Text
    =   λ(names : List Text)
      → λ(args : List FunArg)
      →     Text/concatSep
              "/"
              (   names
                # Optional/fold
                    FunArg
                    (List/head FunArg args)
                    (List Text)
                    (λ(arg : FunArg) → [ "" ])
                    ([] : List Text)
              )
        ++  funArgsSignature args

let createFunType
    : schema.Backend → Text → schema.Constructor → Text
    =   λ(backend : schema.Backend)
      → λ(name : Text)
      → λ(constructor : schema.Constructor)
      → ''
        ${funSignature [ "create" ] constructor.inputs} :
           ${funArgsToDhallFun "∀" constructor.inputs}
            ∀(next : InstType → Plan)
          → ∀(plan : SinglePlan)
          → ∀(tag : Natural)
          → Run
        ''

let createFun
    : schema.Backend → Text → schema.Constructor → Text
    =   λ(backend : schema.Backend)
      → λ(name : Text)
      → λ(constructor : schema.Constructor)
      → ''
        ${funSignature [ "create" ] constructor.inputs} =
           ${funArgsToDhallFun "λ" constructor.inputs}
            λ(next : InstType → Plan)
          → λ(plan : SinglePlan)
          → λ(tag : Natural)
          → next
              (build
                  { address = ${backend.createValue constructor}
                  , def = ${backend.createDef constructor}
                  })
              plan
              (tag + 1)
        ''

let sendType
    : schema.Backend → schema.Fun → Text
    =   λ(backend : schema.Backend)
      → λ(fun : schema.Fun)
      → ''
        ${funSignature [ "send", fun.name ] fun.inputs} :
              ${funArgsToDhallFun "∀" fun.inputs}
              Void
        ''

let send
    : schema.Backend → schema.Fun → Text
    =   λ(backend : schema.Backend)
      → λ(fun : schema.Fun)
      → ''
        ${funSignature [ "send", fun.name ] fun.inputs} =
              ${funArgsToDhallFun "λ" fun.inputs}
              { void = ${backend.sendValue fun}
              , def = ${backend.sendDef fun}
              }
        ''

let callType
    : schema.Backend → schema.Fun → Text
    =   λ(backend : schema.Backend)
      → λ(fun : schema.Fun)
      → ''
        ${funSignature [ "call", fun.name ] fun.inputs} :
            ${funArgsToDhallFun "∀" fun.inputs}
            ∀(next :
                { ${funReturnToDhallType fun.outputs}: Text, def : Def }
              → Plan
            )
          → ∀(plan : SinglePlan)
          → ∀(tag : Natural)
          → Run
        ''

let call
    : schema.Backend → schema.Fun → Text
    =   λ(backend : schema.Backend)
      → λ(fun : schema.Fun)
      → ''
        ${funSignature [ "call", fun.name ] fun.inputs} =
            ${funArgsToDhallFun "λ" fun.inputs}
            λ(next :
                { ${funReturnToDhallType fun.outputs}: Text, def : Def }
              → Plan
            )
          → λ(plan : SinglePlan)
          → λ(tag : Natural)
          → next
              { ${funReturnToDhallType fun.outputs} = ${backend.callValue fun}
              , def = ${backend.callDef fun}
              }
              plan
              (tag + 1)
        ''

let defaultConstructor =
      schema.Op.Constructor
        { inputs = [] : List FunArg
        , payable = False
        , stateMutability = ""
        , type = "constructor"
        }

let abiOpToDhallType
    : schema.Backend → Text → schema.Op → Text
    =   λ(backend : schema.Backend)
      → λ(name : Text)
      → λ(op : schema.Op)
      → merge
          { Function =
              λ(fun : schema.Fun) → "${sendType backend fun}\n, ${callType backend fun}"
          , Fallback = λ(fallback : schema.Fallback) → "fallback : {}"
          , Event = λ(event : schema.Event) → "event/${event.name} : {}"
          , Constructor = createFunType backend name
          }
          op

let abiOpToDhall
    : schema.Backend → Text → schema.Op → Text
    =   λ(backend : schema.Backend)
      → λ(name : Text)
      → λ(op : schema.Op)
      → merge
          { Function =
              λ(fun : schema.Fun) → "${send backend fun}\n, ${call backend fun}"
          , Fallback = λ(fallback : schema.Fallback) → "fallback = {=}"
          , Event = λ(event : schema.Event) → "event/${event.name} = {=}"
          , Constructor = createFun backend name
          }
          op

let abiToDhall
    : schema.Backend → Text → Text → schema.Abi → Text
    =   λ(backend : schema.Backend)
      → λ(prefix : Text)
      → λ(name : Text)
      → λ(ops : schema.Abi)
      → ''
        let lib = ./lib

        let Def = lib.Def

        let DefEntry = lib.DefEntry

        let Void = lib.Void

        let Run = lib.Run

        let SinglePlan = lib.SinglePlan

        let Plan = lib.Plan

        let backend = ./backend

        let prefix = "${prefix}"

        let name = "${name}"

        let InstType
            : Type
            = { address : { address : Text, def : Def }
                ${Text/concatMap
                  schema.Op
                  (λ(op : schema.Op) → ", " ++ (abiOpToDhallType backend name op))
                  (List/filter schema.Op isntConstructor ops)
                  }
              }

        let build
            : ∀(address : { address : Text, def : Def }) → InstType
            = λ(address : { address : Text, def : Def })
            → { address = address
                ${Text/concatMap
                  schema.Op
                  (λ(op : schema.Op) → ", " ++ (abiOpToDhall backend name op))
                  (List/filter schema.Op isntConstructor ops)
                  }
              }

        in  { ${name} = InstType
            , ${name}/build = build
            , ${name}/${Text/concatMapSep
                ''

                , ${name}/''
                schema.Op
                (abiOpToDhall backend name)
                ( if hasConstructor ops
                  then  (List/filter schema.Op isConstructor ops)
                  else  [ defaultConstructor ]
                )}
            }
        ''

in  abiToDhall
