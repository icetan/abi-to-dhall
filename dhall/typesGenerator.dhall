let Text/concatMapSep =
        ./Prelude/Text/concatMapSep
      ? https://prelude.dhall-lang.org/Text/concatMapSep

let List/concatMap =
      ./Prelude/List/concatMap ? https://prelude.dhall-lang.org/List/concatMap

let Backend = (./abiSchema.dhall).Backend

let addListTypes
    : List Text → List Text
    = List/concatMap Text Text (λ(t : Text) → [ t, "${t}_list" ])

let typeToDhallType
    : Text → Text
    = λ(t : Text) → "${t} = { ${t} : Text, def : Def }"

let typeToDhallConstructor
    : Backend → Text → Text
    =   λ ( backend
          : Backend
          )
      → λ(t : Text)
      → ''
        ${t}/build = λ(val : Text) → { ${t} = "${backend.toLiteral
                                                   "val"}", def = ([] : Def)  }
        , ${t}/void = λ(x : { ${t} : Text, def : Def }) → { void = "${backend.toVoid
                                                                        "x.${t}"}", def = x.def }
        ''

let typesToDhallConstructors
    : Backend → List Text → Text
    =   λ(backend : Backend)
      → λ(ls : List Text)
      → "{ ${Text/concatMapSep
               ''
               
               , ''
               Text
               (typeToDhallConstructor backend)
               (addListTypes ls)} }"

let typesToDhallTypes
    : List Text → Text
    =   λ(ls : List Text)
      → "{ ${Text/concatMapSep "\n, " Text typeToDhallType (addListTypes ls)} }"

let typesToDhall
    : Backend → List Text → Text
    =   λ(backend : Backend)
      → λ(ls : List Text)
      → ''
        let Def = List { mapKey : Natural, mapValue : Text }
        
        in ${typesToDhallTypes ls} ⫽ ${typesToDhallConstructors backend ls}
        ''

in  typesToDhall
