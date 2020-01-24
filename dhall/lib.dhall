let Function/identity = ./Prelude/Function/identity

let DefEntry
    : Type
    = { mapKey : Natural, mapValue : Text }

let Def
    : Type
    = List DefEntry

let Void
    : Type
    = { void : Text, def : Def }

let ethToWei
    : Natural → Natural
    = λ(eth : Natural) → eth * 1000000000000000000

let ethToGWei
    : Natural → Natural
    = λ(eth : Natural) → eth * 1000000000

let Void/optional
    : Bool → Void → Void
    =   λ(enable : Bool)
      → λ(v : Void)
      → if enable then v else { void = "", def = [] : Def }

let Run
    : Type
    = List Void

let SinglePlan
    : Type
    = Natural → Run

let SinglePlan/empty
    : SinglePlan
    = λ(tag : Natural) → [] : Run

let Plan
    : Type
    = SinglePlan → SinglePlan

let Plan/empty
    : Plan
    = λ(s : SinglePlan) → s

let Plan/concat
    : List Plan → Plan
    = λ(ps : List Plan) → List/fold Plan ps SinglePlan (Function/identity Plan)

let Plan/build
    : Run → Plan
    = λ(run : Run) → λ(next : SinglePlan) → λ(tag : Natural) → run # next tag

let Plan/buildThen
    : Run → Plan → Plan
    =   λ(run : Run)
      → λ(after : Plan)
      → λ(next : SinglePlan)
      → λ(tag : Natural)
      → run # after next tag

let Plan/optional
    : Bool → Plan → Plan
    = λ(enable : Bool) → λ(p : Plan) → if enable then p else Plan/empty

let StatePlan
    : ∀(s : Type) → Type
    = λ(State : Type) → ∀(s : State) → Plan

let StatePlan/empty
    : ∀(s : Type) → StatePlan s
    = λ(State : Type) → λ(s : State) → Plan/empty

let Module
    : ∀(o : Type) → Type
    = λ(Output : Type) → StatePlan Output → Plan

let StateModule
    : ∀(s : Type) → Type
    = λ(State : Type) → StatePlan State → StatePlan State

let StateModule/concat
    : ∀(s : Type) → List (StateModule s) → StateModule s
    =   λ(State : Type)
      → λ(sms : List (StateModule State))
      → List/fold
          (StateModule State)
          sms
          (StatePlan State)
          (Function/identity (StateModule State))

let StateModule/module
    : ∀(s : Type) → StateModule s → s → Module s
    =   λ(State : Type)
      → λ(sm : StateModule State)
      → λ(s : State)
      → λ(r : StatePlan State)
      → sm r s

let Plan/run
    : Plan → Run
    = λ(p : Plan) → p SinglePlan/empty 0

let StatePlan/run
    : ∀(s : Type) → StatePlan s → s → Run
    = λ(State : Type) → λ(sp : StatePlan State) → λ(s : State) → Plan/run (sp s)

let Module/run
    : ∀(o : Type) → Module o → Run
    =   λ(Output : Type)
      → λ(module : Module Output)
      → Plan/run (module (StatePlan/empty Output))

let StateModule/run
    : ∀(s : Type) → StateModule s → s → Run
    =   λ(State : Type)
      → λ(sm : StateModule State)
      → λ(s : State)
      → Module/run State (StateModule/module State sm s)

in  { ethToWei = ethToWei
    , ethToGWei = ethToGWei
    , Void = Void
    , Def = Def
    , DefEntry = DefEntry
    , Run = Run
    , SinglePlan = SinglePlan
    , Plan = Plan
    , StatePlan = StatePlan
    , Module = Module
    , StateModule = StateModule
    , Void/optional = Void/optional
    , SinglePlan/empty = SinglePlan/empty
    , Plan/build = Plan/build
    , Plan/buildThen = Plan/buildThen
    , Plan/empty = Plan/empty
    , Plan/optional = Plan/optional
    , Plan/concat = Plan/concat
    , Plan/run = Plan/run
    , StatePlan/empty = StatePlan/empty
    , StatePlan/run = StatePlan/run
    , Module/run = Module/run
    , StateModule/module = StateModule/module
    , StateModule/concat = StateModule/concat
    , StateModule/run = StateModule/run
    }
