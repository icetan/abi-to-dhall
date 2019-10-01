let List/any = ./Prelude/List/any

let List/null = ./Prelude/List/null

let Natural/equal = ./Prelude/Natural/equal

let Natural/greaterThan = ./Prelude/Natural/greaterThan

let schema = ./abiSchema.dhall

let Def = schema.Def

let DefEntry = schema.DefEntry

let hasKey
    : Def → DefEntry → Bool
    =   λ(d : Def)
      → λ(e : DefEntry)
      → List/any DefEntry (λ(n : DefEntry) → Natural/equal n.mapKey e.mapKey) d

let insert
    : DefEntry → Def → Def
    =   λ(e : DefEntry)
      → λ(d : Def)
      →       if List/null DefEntry d
        
        then  [ e ]
        
        else  let result =
                    List/fold
                      DefEntry
                      d
                      Def
                      (   λ(x : DefEntry)
                        → λ(acc : Def)
                        →       if hasKey acc e
                          
                          then  [ x ] # acc
                          
                          else  if Natural/greaterThan e.mapKey x.mapKey
                          
                          then  [ x, e ] # acc
                          
                          else  [ x ] # acc
                      )
                      ([] : Def)
              
              in  if hasKey result e then result else [ e ] # result

let insertSort
    : Def → Def
    = λ(d : Def) → List/fold DefEntry d Def insert ([] : Def)

let concatDef : Def → Def → Def = λ(x : Def) → λ(acc : Def) → x # acc

let concatDefs
    : List Def → Def
    = λ(ds : List Def) → List/fold Def ds Def concatDef ([] : Def)

let data1 =
      [ { mapKey = 5, mapValue = "5" }
      , { mapKey = 3, mapValue = "3" }
      , { mapKey = 1, mapValue = "1" }
      , { mapKey = 6, mapValue = "6" }
      ]

let expect1 =
      [ { mapKey = 1, mapValue = "1" }
      , { mapKey = 3, mapValue = "3" }
      , { mapKey = 5, mapValue = "5" }
      , { mapKey = 6, mapValue = "6" }
      ]

let test1 = assert : insertSort data1 ≡ expect1

in  { concatDefs = concatDefs, insertSort = insertSort }

--let insertLog
--    : Def → List Def
--    =   λ(d : Def)
--      → List/fold
--          DefEntry
--          d
--          (List Def)
--          (   λ(x : DefEntry)
--            → λ(log : List Def)
--            →   log
--              # [ insert
--                    x
--                    ( Optional/fold
--                        Def
--                        (List/last Def log)
--                        Def
--                        (λ(d : Def) → d)
--                        ([] : Def)
--                    )
--                ]
--          )
--          ([] : List Def)
