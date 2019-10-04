let Text/concatMapSep =
        ../../Prelude/Text/concatMapSep
      ? https://prelude.dhall-lang.org/Text/concatMapSep

let List/map = ../../Prelude/List/map

let List/any = ../../Prelude/List/any

let Natural/equal = ../../Prelude/Natural/equal

let schema = ../../abiSchema.dhall

let Hex = schema.Hex

let Void = schema.Void

let Def = schema.Def

let DefEntry = schema.DefEntry

let utils = ../../utils.dhall

let concatDefs = utils.concatDefs

let insertSort = utils.insertSort

let def : Void → Def = λ(void : Void) → void.def

let undef
    : Def → Text
    =   λ(def : Def)
      → List/fold
          DefEntry
          def
          Text
          (   λ(e : DefEntry)
            → λ(acc : Text)
            → e.mapValue ++ acc
          )
          ""

let void : Void → Text = λ(void : Void) → void.void

let defineMem
    : Natural → Text → Def
    =   λ ( id
          : Natural
          )
      → λ(code : Text)
      → [
          { mapKey = id
          , mapValue = "_def_${Natural/show id} = ${code};\n"
          }
        ]

let callMem : Natural → Text = λ(id : Natural) → "_def_${Natural/show id}"

let hexToBytes32
    : Hex → { bytes32 : Text, def : Def }
    =   λ(hex : Hex)
      → { bytes32 = hex.hex, def = hex.def }

let asciiToHex
    : Text → Hex
    =   λ(ascii : Text)
      → { hex = "\"${ascii}\"", def = ([] : Def) }

let naturalToUint256
    : Natural → { uint256 : Text, def : Def }
    =   λ(nat : Natural)
      → { uint256 = Natural/show nat, def = ([] : Def) }

let sig
    : Text → Hex
    = λ(t : Text) → { hex = "bytes4(keccak256(\"${t}\"))", def = ([] : Def) }

let toSol
    : List Void → Text
    =   λ(vs : List Void)
      → ''
        pragma solidity >=0.4.23;

        import "ds-test/test.sol";
        import "ds-token/token.sol";
        import "ds-guard/guard.sol";

        contract DSTokenTest is DSTest {
            function testGasEstimate() public {
                /* Definitions */
        ${undef (insertSort (concatDefs (List/map Void Def def vs)))}

        /* Executions */
        ${Text/concatMapSep "\n" Void void vs}
            }

        }
        ''

let renderUtil
    : schema.BackendUtil
    = { concatDefs = concatDefs
      , defineMem = defineMem
      , callMem = callMem
      , sig = sig
      , hexToBytes32 = hexToBytes32
      , asciiToHex = asciiToHex
      , naturalToUint256 = naturalToUint256
      , render = toSol
      }

in  renderUtil
