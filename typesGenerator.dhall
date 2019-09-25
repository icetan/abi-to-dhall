let Text/concatMapSep =
        ~/src/dhall-lang/Prelude/Text/concatMapSep
      ? https://prelude.dhall-lang.org/Text/concatMapSep

let List/concatMap =
        ~/src/dhall-lang/Prelude/List/concatMap
      ? https://prelude.dhall-lang.org/List/concatMap

let addListTypes
    : List Text → List Text
    = List/concatMap Text Text (λ(t : Text) → [ t, "${t}_list" ])

let typeToDhallType
    : Text → Text
    = λ(t : Text) → "${t} = { ${t} : Text, def : Text }"

let typeToDhallConstructor
    : Text → Text
    = λ(t : Text) → "${t} = λ(val : Text) → { ${t} = val, def = \"\" }\n"

-- TODO: generalize rendering of memoized constructor
--
--  , ${t}_mem = λ(tag : Text) → λ(val : Text) → { ${t} = lib.callMem tag, def = lib.defineMem tag val }

let typesToDhallConstructors
    : List Text → Text
    =   λ(ls : List Text)
      → ''
        let lib = ./lib.dhall
        
        in { ${Text/concatMapSep
               ''
               
               , ''
               Text
               typeToDhallConstructor
               (addListTypes ls)} }
        ''

let typesToDhallTypes
    : List Text → Text
    =   λ(ls : List Text)
      → ''
        { ${Text/concatMapSep "\n, " Text typeToDhallType (addListTypes ls)} }
        ''

in  { constructors = typesToDhallConstructors, types = typesToDhallTypes }
