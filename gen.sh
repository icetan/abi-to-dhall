#!/usr/bin/env bash
set -e

filepath() {
  echo "$(cd ${1%/*} && pwd)/${1##*/}"
}

LIB_DIR=$(cd "${0%/*}" && pwd)
OUT_ABI_DIR="$PWD/abi"
OUT_LIB_DIR="$PWD/lib"
RENDER_PATH=$(filepath "$1")
RENDER_LIB_PATH=$(cd ${RENDER_PATH%/*} && filepath $(dhall text <<<"($RENDER_PATH).libPath"))

gen() {
  local abiPath
  abiPath="$1"
  local contractName
  contractName="${abiPath##*/}"
  contractName="${contractName%.*}"

  echo -n >&2 "$abiPath → "

  if {
    sed 's/\[\]"/_list"/g' "$abiPath" \
      | json-to-dhall --records-strict --unions-strict "($LIB_DIR/abiSchema.dhall).Abi" \
      > "$OUT_ABI_DIR/abi_$contractName.dhall"
    dhall text <<<"$LIB_DIR/abiGenerator.dhall \"$contractName\" $RENDER_PATH $OUT_ABI_DIR/abi_$contractName.dhall" \
      | dhall format > "$OUT_ABI_DIR/$contractName"
  }; then
    echo >&2 "$OUT_ABI_DIR/$contractName"
  else
    echo >&2 "Failed!"
  fi
}

rm -rf "$OUT_ABI_DIR" "$OUT_LIB_DIR"
mkdir -p "$OUT_ABI_DIR" "$OUT_LIB_DIR"
cp "$LIB_DIR/lib.dhall" "$OUT_LIB_DIR/default"
cp "$RENDER_LIB_PATH" "$OUT_LIB_DIR/render"

types='
  [ "void"
  , "hex"
  , "address"
  , "uint256"
  , "bytes"
  , "bytes4"
  , "bytes32"
  ]'

dhall text <<<"($LIB_DIR/typesGenerator.dhall).constructors $types" \
  | dhall format > "$OUT_LIB_DIR/typeConstructors"
dhall text <<<"($LIB_DIR/typesGenerator.dhall).types $types" \
  | dhall format > "$OUT_LIB_DIR/types"

for fn in "${@:2}"; do gen "$fn"; done
