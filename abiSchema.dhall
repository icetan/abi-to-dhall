let SimpleArg =
      { name : Text
      , type : Text
      }

let ComplexArg =
      SimpleArg ⩓ { components : List SimpleArg }

let FunArg = < Simple : SimpleArg | Complex : ComplexArg >

let EvArg =
    { indexed : Bool
    , name : Text
    , type : Text
    }

let Fun =
    { constant : Bool
    , name : Text
    , inputs : List FunArg
    , outputs : List FunArg
    , payable : Bool
    , stateMutability : Text
    , type : Text
    }

let Fallback =
    { payable : Bool
    , stateMutability : Text
    , type : Text
    }

let Constructor =
    { inputs : List FunArg
    , payable : Bool
    , stateMutability : Text
    , type : Text
    }

let Event =
    { name : Text
    , anonymous : Bool
    , inputs : List EvArg
    , type : Text
    }

let Op = < Function : Fun | Event : Event | Constructor : Constructor | Fallback : Fallback >
let Abi = List Op

let Render : Type =
    { libPath : Text
    , sendValue : ∀(fun : Fun) → Text
    , sendDef : ∀(fun : Fun) → Text
    , callValue : ∀(fun : Fun) → Text
    , callDef : ∀(fun : Fun) → Text
    , createValue : ∀(constructor : Constructor) → Text
    , createDef : ∀(constructor : Constructor) → Text
    }

in  { Abi =
        Abi
    , Op =
        Op
    , Constructor =
        Constructor
    , Event =
        Event
    , Fun =
        Fun
    , Fallback =
        Fallback
    , FunArg =
        FunArg
    , EvArg =
        EvArg
    , SimpleArg =
        SimpleArg
    , ComplexArg =
        ComplexArg
    , Render =
        Render
    }
