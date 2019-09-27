let SimpleArg = { name : Text, type : Text }

let ComplexArg = SimpleArg ⩓ { components : List SimpleArg }

let FunArg = < Simple : SimpleArg | Complex : ComplexArg >

let EvArg = { indexed : Bool, name : Text, type : Text }

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

let Hex : Type = { hex : Text, def : Text }

let Void : Type = { void : Text, def : Text }

let BackendUtil
    : Type
    = { defineMem : Text → Text → Text
      , callMem : Text → Text
      , concatDefs : List Text → Text
      , sig : Text → Hex
      , bytes32FromHex : Hex → { bytes32 : Text, def : Text }
      , asciiToHex : Text → Hex
      , addressToVoid : { address : Text, def : Text } → Void
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
    , ComplexArg = ComplexArg
    , BackendUtil = BackendUtil
    , Backend = Backend
    , Hex = Hex
    , Void = Void
    }
