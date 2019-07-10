#!/usr/bin/env bash
set -e

LIB_DIR=$(cd "${0%/*}" && pwd)
OUT_DIR="$PWD/abi"

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
      > "$OUT_DIR/abi_$contractName.dhall"
    dhall text <<<"$LIB_DIR/abiGenerator.dhall \"$contractName\" $OUT_DIR/abi_$contractName.dhall" \
      | dhall format > "$OUT_DIR/$contractName"
  }; then
    echo >&2 "$OUT_DIR/$contractName"
  else
    echo >&2 "Failed!"
  fi
}

mkdir -p "$OUT_DIR"
cp "$LIB_DIR/lib.dhall" "$OUT_DIR"

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
  | dhall format > "$OUT_DIR/typeConstructors.dhall"
dhall text <<<"($LIB_DIR/typesGenerator.dhall).types $types" \
  | dhall format > "$OUT_DIR/types.dhall"

for fn in "$@"; do gen "$fn"; done
