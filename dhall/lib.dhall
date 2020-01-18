let List/map = ./Prelude/List/map ? https://prelude.dhall-lang.org/List/map

let DefEntry : Type = { mapKey : Natural, mapValue : Text }

let Def : Type = List DefEntry

let Void : Type = { void : Text, def : Def }

let ethToWei : Natural → Natural = λ(eth : Natural) → eth * 1000000000000000000

let ethToGWei : Natural → Natural = λ(eth : Natural) → eth * 1000000000

let Void/optional
    : Bool → Void → Void
    =   λ(enable : Bool)
      → λ(v : Void)
      → if enable then v else { void = "", def = [] : Def }

let Run : Type = List Void

let SinglePlan : Type = Natural → Run

let SinglePlan/empty : SinglePlan = λ(tag : Natural) → [] : Run

let Plan : Type = SinglePlan → SinglePlan

let Plan/empty : Plan = λ(s : SinglePlan) → s

let Plan/flatten
    : Plan → SinglePlan → SinglePlan
    = λ(p : Plan) → λ(s : SinglePlan) → p s

let Plan/concat
    : List Plan → Plan
    =   λ(ps : List Plan)
      → λ(s : SinglePlan)
      → List/fold Plan ps SinglePlan Plan/flatten s

let Plan/run
    : Run → Plan
    = λ(run : Run) → λ(next : SinglePlan) → λ(tag : Natural) → run # next tag

let Plan/runThen
    : Run → Plan → Plan
    =   λ(run : Run)
      → λ(after : Plan)
      → λ(next : SinglePlan)
      → λ(tag : Natural)
      → run # after next tag

let Plan/runAll
    : List Plan → Plan
    =   λ(ps : List Plan)
      → λ(next : SinglePlan)
      → λ(tag : Natural)
      → Plan/concat ps next tag

let Plan/optional
    : Bool → Plan → Plan
    = λ(enable : Bool) → λ(p : Plan) → if enable then p else Plan/empty

let Plan/deploy
    : Plan → Run
    = λ(p : Plan) → p SinglePlan/empty 0

let Module : ∀(c : Type) → Type = λ(c : Type) → c → Plan

let Module/empty
    : ∀(c : Type) → c → Plan
    = λ(Config : Type) → λ(c : Config) → Plan/empty

let Module/optional
    : Bool → ∀(c : Type) → Module c → Module c
    =   λ(enable : Bool)
      → λ(Config : Type)
      → λ(m : Module Config)
      → if enable then m else Module/empty Config

let Deploy : ∀(c : Type) → Type = λ(c : Type) → List (Module c)

let Deploy/deploy
    : ∀(c : Type) → Deploy c → c → Run
    =   λ(Config : Type)
      → λ(ms : List (Module Config))
      → λ(c : Config)
      → Plan/concat
          (List/map (Module Config) Plan (λ(m : Module Config) → m c) ms)
          SinglePlan/empty
          0

in  { ethToWei = ethToWei
    , ethToGWei = ethToGWei
    , Void = Void
    , Void/optional = Void/optional
    , Def = Def
    , DefEntry = DefEntry
    , Run = Run
    , SinglePlan = SinglePlan
    , SinglePlan/empty = SinglePlan/empty
    , Plan = Plan
    , Plan/empty = Plan/empty
    , Plan/flatten = Plan/flatten
    , Plan/concat = Plan/concat
    , Plan/run = Plan/run
    , Plan/runThen = Plan/runThen
    , Plan/runAll = Plan/runAll
    , Plan/optional = Plan/optional
    , Plan/deploy = Plan/deploy
    , Module = Module
    , Module/empty = Module/empty
    , Module/optional = Module/optional
    , Deploy = Deploy
    , Deploy/deploy = Deploy/deploy
    }
