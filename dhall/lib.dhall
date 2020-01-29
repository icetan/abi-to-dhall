let Function/identity = ./Prelude/Function/identity

let Optional/map = ./Prelude/Optional/map

let Optional/default = ./Prelude/Optional/default

let List/map = ./Prelude/List/map

let Map = ./Prelude/Map/Type

let Entry = ./Prelude/Map/Entry

let DefEntry
    : Type
    = Entry Natural Text

let Def
    : Type
    = List DefEntry

let Void
    : Type
    = { _void : Text, def : Def } -- size : Natural,

let ethToWei
    : Natural → Natural
    = λ(eth : Natural) → eth * 1000000000000000000

let ethToGWei
    : Natural → Natural
    = λ(eth : Natural) → eth * 1000000000

let Void/empty
    : Void
    = { _void = "", def = [] : Def } -- size = 0,

let Void/optional
    : Optional Void → Void
    = Optional/default Void Void/empty

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
    : Optional Plan → Plan
    = Optional/default Plan Plan/empty

let StatePlan
    : ∀(s : Type) → Type
    = λ(s : Type) → s → Plan

let StatePlan/empty
    : ∀(s : Type) → StatePlan s
    = λ(s : Type) → λ(_ : s) → Plan/empty

let Module
    : ∀(o : Type) → Type
    = λ(o : Type) → StatePlan o → Plan

let Module/default
    : ∀(t : Type) → Module t → Optional t → Module t
    =   λ(t : Type)
      → λ(default : Module t)
      → λ(o : Optional t)
      → λ(sp : StatePlan t)
      → Optional/default Plan (default sp) (Optional/map t Plan sp o)

let Module/fork
    : ∀(a : Type) → ∀(b : Type) → (a → Module b) → Optional a → Module (Optional b)
    =   λ(a : Type)
      → λ(b : Type)
      → λ(f : a → StatePlan b → Plan)
      → λ(o : Optional a)
      → λ(sp : StatePlan (Optional b))
      → (Optional/default
          (Module (Optional b))
          (λ(return : StatePlan (Optional b)) → return (None b))
          (Optional/map
            a
            (Module (Optional b))
            (λ(x : a)
            → (λ(return : StatePlan (Optional b))
              → (f x (λ(y : b) → return (Some y)))
              ))
            o)
          ) sp

let Module/optional
    : ∀(a : Type) → ∀(b : Type) → (a → b) → Optional a → Module (Optional b)
    =   λ(a : Type)
      → λ(b : Type)
      → λ(f : a → b)
      → λ(o : Optional a)
      → λ(sp : StatePlan (Optional b))
      → sp (Optional/map a b f o)

let StateModule
    : ∀(s : Type) → Type
    = λ(s : Type) → StatePlan s → StatePlan s

let StateModule/concat
    : ∀(s : Type) → List (StateModule s) → StateModule s
    =   λ(s : Type)
      → λ(sms : List (StateModule s))
      → List/fold
          (StateModule s)
          sms
          (StatePlan s)
          (Function/identity (StateModule s))

let StateModule/module
    : ∀(s : Type) → StateModule s → s → Module s
    =   λ(s : Type)
      → λ(module : StateModule s)
      → λ(state : s)
      → λ(return : StatePlan s)
      → module return state

let Plan/run
    : Plan → Run
    = λ(p : Plan) → p SinglePlan/empty 0

let StatePlan/run
    : ∀(s : Type) → StatePlan s → s → Run
    = λ(State : Type) → λ(sp : StatePlan State) → λ(s : State) → Plan/run (sp s)

let Module/plan
    : ∀(o : Type) → Module o → Plan
    =   λ(o : Type)
      → λ(module : Module o)
      → module (StatePlan/empty o)

let Module/run
    : ∀(o : Type) → Module o → Run
    =   λ(o : Type)
      → λ(module : Module o)
      → Plan/run (Module/plan o module)

let StateModule/run
    : ∀(s : Type) → StateModule s → s → Run
    =   λ(State : Type)
      → λ(sm : StateModule State)
      → λ(s : State)
      → Module/run State (StateModule/module State sm s)

let Plan/outputs
    : ∀(t : Type) → (Text → t → Void) → Map Text t → Plan
    =   λ(t : Type)
      → λ(f : Text → t → Void)
      → λ(m : Map Text t)
      → Plan/build
          (List/map
            (Entry Text t)
            Void
            (λ(x : Entry Text t) → f x.mapKey x.mapValue)
            m
          )

in  { ethToWei = ethToWei
    , ethToGWei = ethToGWei
    , Void = Void
    , Def = Def
    , DefEntry = DefEntry
    , Run = Run
    , SinglePlan = SinglePlan
    , Plan = Plan
    --, StatePlan = StatePlan
    , Module = Module
    --, StateModule = StateModule
    , Void/empty = Void/empty
    , Void/optional = Void/optional
    , SinglePlan/empty = SinglePlan/empty
    , Plan/build = Plan/build
    , Plan/buildThen = Plan/buildThen
    , Plan/empty = Plan/empty
    , Plan/optional = Plan/optional
    , Plan/concat = Plan/concat
    , Plan/run = Plan/run
    , Plan/outputs = Plan/outputs
    --, StatePlan/empty = StatePlan/empty
    --, StatePlan/run = StatePlan/run
    , Module/default = Module/default
    , Module/optional = Module/optional
    , Module/fork = Module/fork
    , Module/plan = Module/plan
    , Module/run = Module/run
    --, StateModule/module = StateModule/module
    --, StateModule/concat = StateModule/concat
    --, StateModule/run = StateModule/run
    }
