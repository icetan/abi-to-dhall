let List/any = ./Prelude/List/any

let Natural/equal = ./Prelude/Natural/equal

let schema = ./abiSchema.dhall

let Def = schema.Def

let DefEntry = schema.DefEntry

let concatDef
    : Def → Def → Def
    =   λ(x : Def)
      → λ(acc : Def)
      → List/fold
          DefEntry
          x
          Def
          (   λ(e : DefEntry)
            → λ(acc : Def)
            →       if List/any DefEntry (λ(n : DefEntry) → Natural/equal n.mapKey e.mapKey) acc
              then  acc
              else  acc # [ e ]
          )
          acc

let concatDefs
    : List Def → Def
    =   λ(defs : List Def)
      → List/fold
          Def
          defs
          Def
          concatDef
          ([] : Def)

in {
  concatDefs = concatDefs
}
