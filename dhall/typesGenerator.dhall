let Text/concatMapSep =
        ./Prelude/Text/concatMapSep
      ? https://prelude.dhall-lang.org/Text/concatMapSep

let List/concatMap =
      ./Prelude/List/concatMap ? https://prelude.dhall-lang.org/List/concatMap

let Backend = (./abiSchema.dhall).Backend

let Helper = ./typesHelper.dhall

let ConvType = Helper.Conv.Type

let typeToDhallType
    : ConvType → Text
    =   λ(t : ConvType)
      → ''
        ${t.name} = { ${t.name} : Text, def : Def }
        ,${t.name}_list = { ${t.name}_list : Text, def : Def }
        ''

let typeToDhallConstructor
    : Backend → ConvType → Text
    =   λ ( backend
          : Backend
          )
      → λ(t : ConvType)
      → ''
        ${t.name}/build =
            λ(val : ${t.type})
          → { ${t.name} = "${backend.toLiteral "((${t.conv}) val)"}"
            , def = ([] : Def)
            }
        , ${t.name}_list/build =
            λ(val : List ${t.type})
          → { ${t.name}_list = "${
                backend.toListLiteral "./Prelude/List/map ${t.type} Text (${t.conv}) val"
              }"
            , def = ([] : Def)
            }
        , ${t.name}/output =
          λ(id : Text) → λ(x : { ${t.name} : Text, def : Def }) → {
            void = "${backend.toOutput "x.${t.name}"}", def = x.def
          }
        , ${t.name}_list/output =
          λ(id : Text) → λ(x : { ${t.name} : Text, def : Def }) → {
            void = "${backend.toOutput "x.${t.name}"}", def = x.def
          }
        ''

let typesToDhallConstructors
    : Backend → List ConvType → Text
    =   λ(backend : Backend)
      → λ(ls : List ConvType)
      → "{ ${Text/concatMapSep
               ''
               
               , ''
               ConvType
               (typeToDhallConstructor backend)
               ls} }"

let typesToDhallTypes
    : List ConvType → Text
    =   λ(ls : List ConvType)
      → "{ ${Text/concatMapSep "\n, " ConvType typeToDhallType ls} }"

let typesToDhall
    : Backend → List ConvType → Text
    =   λ(backend : Backend)
      → λ(ls : List ConvType)
      → ''
        let Def = List { mapKey : Natural, mapValue : Text }
        
        in ${typesToDhallTypes ls} ⫽ ${typesToDhallConstructors backend ls}
        ''

in  typesToDhall
