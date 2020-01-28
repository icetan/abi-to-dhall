let Text/concatMapSep = ./Prelude/Text/concatMapSep

let Backend = (./abiSchema.dhall).Backend

let Helper = ./typesHelper.dhall

let ConvType = Helper.Conv.Type

let typeToDhallTypeLet
    : Backend → ConvType → Text
    =   λ(backend : Backend)
      → λ(t : ConvType)
      → ''
        let ${t.name} = { _${t.group} : Text, def : Def } -- size : Natural, 
        let ${t.name}List = { _${t.group}_list : Text, def : Def } -- size : Natural, 

        let ${t.name}/build =
              λ(val : ${t.type})
            → { _${t.group} = "${backend.toLiteral
                                  "${t.evm}"
                                  "((${t.conv}) val)"}"
              --, size = $ {Natural/show t.size}
              , def = ([] : Def)
              }
        let ${t.name}List/build =
              λ(val : List ${t.type})
            → { _${t.group}_list = "${backend.toListLiteral
                                       "${t.evm}"
                                       "./Prelude/List/map ${t.type} Text (${t.conv}) val"}"
              --, size = $ {Natural/show t.size}
              , def = ([] : Def)
              }

        ''

let typeToDhallExport
    : Backend → ConvType → Text
    =   λ(backend : Backend)
      → λ(t : ConvType)
      → ''
        ${t.name} = ${t.name}
        , ${t.name}List = ${t.name}List

        , ${t.name}/build = ${t.name}/build
        , ${t.name}List/build = ${t.name}List/build

        , evm/${t.evm} =
              λ(v : Text)
            → λ(d : Def)
            → { _${t.group} = v, def = d } --, size = $ {Natural/show t.size} }
        , evm/${t.evm}_list =
              λ(v : Text)
            → λ(d : Def)
            → { _${t.group}_list = v, def = d } --, size = $ {Natural/show t.size} }

        , evm/${t.evm}/value =
              λ(v : ${t.name})
            → v._${t.group}
        , evm/${t.evm}_list/value =
              λ(v : ${t.name}List)
            → v._${t.group}_list

        , evm/${t.evm}/Type = ${t.name}
        , evm/${t.evm}_list/Type = ${t.name}List

        --, evm/${t.evm}/size = $ {Natural/show t.size}
        --, evm/${t.evm}_list/size = $ {Natural/show t.size}

        , ${t.name}/output =
              λ(id : Text) → λ(x : ${t.name})
            → { _void = "${backend.toOutput "${t.evm}" "x._${t.group}"}"
              --, size = 0
              , def = x.def
              }
        , ${t.name}List/output =
              λ(id : Text) → λ(x : ${t.name}List)
            → { _void = "${backend.toOutput "${t.evm}" "x._${t.group}_list"}"
              --, size = 0
              , def = x.def
              }
        ''

let typeToDhallReadType
    : ConvType → Text
    =   λ(t : ConvType)
      → ''
        let ${t.name}/Read = { ${t.name} : Text }
        let ${t.name}List/Read = { ${t.name}List : List Text }
        ''

let typeToDhallReadTypeUnion
    : ConvType → Text
    =   λ(t : ConvType)
      → ''
        | ${t.name} : ${t.name}/Read
        | ${t.name}List : ${t.name}List/Read
        ''

let typeToDhallReadTypeMerge
    : ConvType → Text
    =   λ(t : ConvType)
      → ''
          ${t.name} = λ(v : ${t.name}/Read) → ${t.name}/build v.${t.name}
        , ${t.name}List = λ(v : ${t.name}List/Read) → ${t.name}List/build v.${t.name}List
        ''

let typesToDhallTypeLets
    : Backend → List ConvType → Text
    =   λ(backend : Backend)
      → λ(ls : List ConvType)
      → "${Text/concatMapSep
               ''

               ''
               ConvType
               (typeToDhallTypeLet backend)
               ls}"

let typesToDhallExports
    : Backend → List ConvType → Text
    =   λ(backend : Backend)
      → λ(ls : List ConvType)
      → "{ ${Text/concatMapSep
               ''

               , ''
               ConvType
               (typeToDhallExport backend)
               ls} }"

let typesToDhall
    : Backend → List ConvType → Text
    =   λ(backend : Backend)
      → λ(ls : List ConvType)
      → ''
        let Def = List { mapKey : Natural, mapValue : Text }

        ${typesToDhallTypeLets backend ls}

        in ${typesToDhallExports backend ls}
        ''

in  typesToDhall
