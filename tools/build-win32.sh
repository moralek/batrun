#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LAZARUS_DIR="${BATRUN_LAZARUS_DIR:-/usr/lib/lazarus/default}"
PCP_DIR="${BATRUN_LAZARUS_PCP:-$ROOT_DIR/target/lazarus-pcp-win32}"
FPC_WIN32_COMPILER="${BATRUN_FPC_WIN32_COMPILER:-ppc386}"

mkdir -p "$PCP_DIR"

if ! command -v "$FPC_WIN32_COMPILER" >/dev/null 2>&1; then
  echo "Win32/i386 compiler not found in PATH: $FPC_WIN32_COMPILER" >&2
  echo "Expected a global ppc386, for example /usr/local/bin/ppc386." >&2
  exit 1
fi
FPC_WIN32_COMPILER="$(command -v "$FPC_WIN32_COMPILER")"

echo "Using Win32/i386 compiler: $FPC_WIN32_COMPILER"

lazbuild \
  --pcp="$PCP_DIR" \
  --lazarusdir="$LAZARUS_DIR" \
  --os=win32 \
  --cpu=i386 \
  --compiler="$FPC_WIN32_COMPILER" \
  "$ROOT_DIR/batrun.lpi"

echo "Built $ROOT_DIR/target/batrun.exe"
