let SimpleArg = { name : Text, type : Text }

let SimpleArgV2 = SimpleArg ⩓ { internalType : Text }

let ComplexArg = SimpleArg ⩓ { components : List SimpleArg }

let ComplexArgV2 = SimpleArgV2 ⩓ { components : List SimpleArgV2 }

let FunArg =
      < Simple : SimpleArg
      | Complex : ComplexArg
      | SimpleV2 : SimpleArgV2
      | ComplexV2 : ComplexArgV2
      >

-- TODO: Make EvArg into a Union of EvArg | EvArgV2 instead of using Optional fields
--let EvArgV2 = EvArg ⩓ { internalType : Text }
--let EventArg = < Arg : EvArg | ArgV2 : EvArgV2 >
let EvArg =
      { indexed : Bool, name : Text, type : Text, internalType : Optional Text }

let Fun =
      { constant : Bool
      , name : Text
      , inputs : List FunArg
      , outputs : List FunArg
      , payable : Bool
      , stateMutability : Text
      , type : Text
      }

let Fallback = { payable : Bool, stateMutability : Text, type : Text }

let Constructor =
      { inputs : List FunArg
      , payable : Bool
      , stateMutability : Text
      , type : Text
      }

let Event = { name : Text, anonymous : Bool, inputs : List EvArg, type : Text }

let Op =
      < Function : Fun
      | Event : Event
      | Constructor : Constructor
      | Fallback : Fallback
      >

let Abi = List Op

let DefEntry
    : Type
    = { mapKey : Natural, mapValue : Text }

let Def
    : Type
    = List DefEntry

let TypeBase
    : Type
    = { def : Def } -- size : Natural,

let Hex =
      { Type = TypeBase ⩓ { _hex : Text }
      , default = { _hex = "", def = [] : Def } -- size = 0,
      }

let Void
    : Type
    = TypeBase ⩓ { _void : Text }

let BackendUtil
    : Type
    = { defineMem : Natural → Text → Def
      , callMem : Natural → Text
      , concatDefs : List Def → Def
      , sig : Text → Hex.Type
      , asciiToHex : Text → Hex.Type
      , render : List Void → Text
      }

let Backend
    : Type
    = { sendValue : ∀(fun : Fun) → Text
      , sendDef : ∀(fun : Fun) → Text
      , callValue : ∀(fun : Fun) → Text
      , callDef : ∀(fun : Fun) → Text
      , createValue : ∀(constructor : Constructor) → Text
      , createDef : ∀(constructor : Constructor) → Text
      , toOutput : Text → Text → Text
      , toLiteral : Text → Text → Text
      , toListLiteral : Text → Text → Text
      , toHex : Text → Text → Text
      , fromHex : Text → Text → Text
      , util : BackendUtil
      }

in  { Abi = Abi
    , Op = Op
    , Constructor = Constructor
    , Event = Event
    , Fun = Fun
    , Fallback = Fallback
    , FunArg = FunArg
    , EvArg = EvArg
    , SimpleArg = SimpleArg
    , SimpleArgV2 = SimpleArgV2
    , ComplexArg = ComplexArg
    , ComplexArgV2 = ComplexArgV2
    , BackendUtil = BackendUtil
    , Backend = Backend
    , TypeBase = TypeBase
    , Hex = Hex
    , Void = Void
    , DefEntry = DefEntry
    , Def = Def
    }
