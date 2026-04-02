#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_FILE="${1:-$ROOT_DIR/target/fpc-win32.cfg}"
FPC_UNITS_ROOT="${BATRUN_FPC_WIN32_UNITS_ROOT:-/tmp/fpc-win32-manual/app/units/i386-win32}"
LAZARUS_DIR="${BATRUN_LAZARUS_DIR:-/usr/lib/lazarus/default}"
BINUTILS_DIR="${BATRUN_BINUTILS_DIR:-/usr/bin}"
MINGW_PREFIX="${BATRUN_MINGW_PREFIX:-i686-w64-mingw32-}"

if [[ ! -d "$FPC_UNITS_ROOT" ]]; then
  echo "Win32 FPC units root not found: $FPC_UNITS_ROOT" >&2
  exit 1
fi

if [[ ! -d "$LAZARUS_DIR" ]]; then
  echo "Lazarus directory not found: $LAZARUS_DIR" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUT_FILE")"

{
  printf '%s\n' "-XP$MINGW_PREFIX"
  printf '%s\n' "-FD$BINUTILS_DIR"

  while IFS= read -r UnitDir; do
    printf '%s\n' "-Fu$UnitDir"
  done < <(find "$FPC_UNITS_ROOT" -mindepth 1 -maxdepth 1 -type d | sort)

  printf '%s\n' "-Fu$LAZARUS_DIR/lcl/units/i386-win32"
  printf '%s\n' "-Fu$LAZARUS_DIR/lcl/units/i386-win32/win32"
  printf '%s\n' "-Fu$LAZARUS_DIR/components/lazutils/lib/i386-win32"
  printf '%s\n' "-Fu$LAZARUS_DIR/components/freetype/lib/i386-win32"
  printf '%s\n' "-Fu$LAZARUS_DIR/packager/units/i386-win32"
} > "$OUT_FILE"

echo "Generated $OUT_FILE"
