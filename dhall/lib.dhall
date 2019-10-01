let List/map =
        ./Prelude/List/map
      ? https://prelude.dhall-lang.org/List/map

let Def : Type = List { mapKey : Natural, mapValue : Text }

let Void : Type = { void : Text, def : Def }

let ethToWei : Natural → Natural = λ(eth : Natural) → eth * 1000000000000000000

let ethToGWei : Natural → Natural = λ(eth : Natural) → eth * 1000000000

let toUint256
    : Natural → { uint256 : Text, def : Def }
    = λ(nat : Natural) → { uint256 = Natural/show nat, def = [] : Def }

let optionalVoid
    : Optional Void → Void
    =   λ(v : Optional Void)
      → Optional/fold
          Void
          v
          Void
          (λ(v : Void) → v)
          { void = "", def = [] : Def }

let Deploy : Type = Natural → List Void

let ChainableDeploy : Type = Deploy → Deploy

let Deploy/empty : Deploy = λ(tag : Natural) → [] : List Void

let chainDeploys
    : ChainableDeploy → Deploy → Deploy
    = λ(cd : ChainableDeploy) → λ(chain : Deploy) → cd chain

let Deploy/chain
    : List ChainableDeploy → Deploy
    =   λ(deploys : List ChainableDeploy)
      → List/fold ChainableDeploy deploys Deploy chainDeploys Deploy/empty

let Deploy/deploy
    : ∀(c : Type) → List (c → ChainableDeploy) → c → List Void
    =   λ(Config : Type)
      → λ(deploys : List (Config → ChainableDeploy))
      → λ(c : Config)
      → Deploy/chain
          ( List/map
              (Config → ChainableDeploy)
              ChainableDeploy
              (λ(d : Config → ChainableDeploy) → d c)
              deploys
          )
          0

let Deploy/plan
    : List Void → ChainableDeploy
    =   λ(plan : List Void)
      → λ(next : Deploy)
      → λ(tag : Natural)
      → plan # next tag

in  { ethToWei = ethToWei
    , ethToGWei = ethToGWei
    , toUint256 = toUint256
    , optionalVoid = optionalVoid
    , Def = Def
    , ChainableDeploy = ChainableDeploy
    , Deploy = Deploy
    , Deploy/empty = Deploy/empty
    , Deploy/chain = Deploy/chain
    , Deploy/deploy = Deploy/deploy
    , Deploy/plan = Deploy/plan
    }
