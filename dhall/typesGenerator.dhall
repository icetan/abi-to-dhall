let Text/concatMapSep = ./Prelude/Text/concatMapSep

let Backend = (./abiSchema.dhall).Backend

let Helper = ./typesHelper.dhall

let ConvType = Helper.Conv.Type

let concatMapConvType = Text/concatMapSep "\n" ConvType

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

        let ${t.name}/hex =
              λ(val : ${t.name})
            → { _hex = "${backend.toHex
                                  "${t.evm}"
                                  "val._${t.group}"}"
              --, size = $ {Natural/show t.size}
              , def = val.def
              }

        let ${t.name}/fromHex =
              λ(val : Hex)
            → { _${t.group} = "${backend.fromHex
                                  "${t.evm}"
                                  "val._hex"}"
              --, size = $ {Natural/show t.size}
              , def = val.def
              }

        let ${t.name}/output =
              λ(id : Text) → λ(x : ${t.name})
            → { _void = "${backend.toOutput "${t.evm}" "x._${t.group}"}"
              , def = x.def
              }
        let ${t.name}List/output =
              λ(id : Text) → λ(x : ${t.name}List)
            → { _void = "${backend.toOutput "${t.evm}" "x._${t.group}_list"}"
              , def = x.def
              }
        ''

let typeToDhallExport
    : Backend → ConvType → Text
    =   λ(backend : Backend)
      → λ(t : ConvType)
      → ''
        , ${t.name} = ${t.name}
        , ${t.name}List = ${t.name}List

        , ${t.name}/build = ${t.name}/build
        , ${t.name}List/build = ${t.name}List/build

        , ${t.name}/hex = ${t.name}/hex
        , ${t.name}/fromHex = ${t.name}/fromHex

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

        , ${t.name}/output = ${t.name}/output
        , ${t.name}List/output = ${t.name}List/output
        ''

let typesToDhallTypeLets
    : Backend → List ConvType → Text
    =   λ(backend : Backend)
      → λ(ls : List ConvType)
      → "${Text/concatMapSep
               "\n"
               ConvType
               (typeToDhallTypeLet backend)
               ls}"

let typesToDhallExports
    : Backend → List ConvType → Text
    =   λ(backend : Backend)
      → λ(ls : List ConvType)
      → "{ ${Text/concatMapSep
               "\n"
               ConvType
               (typeToDhallExport backend)
               ls} }"

let typesToDhall
    : Backend → List ConvType → Text
    =   λ(backend : Backend)
      → λ(ls : List ConvType)
      → ''
        let Def = List { mapKey : Natural, mapValue : Text }

        let Hex = { _hex : Text, def : List Def } --, size : Natural }

        ${typesToDhallTypeLets backend ls}

        in ${typesToDhallExports backend ls}
        ''

in  typesToDhall
