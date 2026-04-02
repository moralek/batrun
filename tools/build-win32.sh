#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LAZARUS_DIR="${BATRUN_LAZARUS_DIR:-/usr/lib/lazarus/default}"
PCP_DIR="${BATRUN_LAZARUS_PCP:-$ROOT_DIR/target/lazarus-pcp-win32}"
CFG_FILE="${BATRUN_FPC_WIN32_CFG:-$ROOT_DIR/target/fpc-win32.cfg}"

mkdir -p "$PCP_DIR"
"$ROOT_DIR/tools/write-fpc-win32-cfg.sh" "$CFG_FILE"

lazbuild \
  --pcp="$PCP_DIR" \
  --lazarusdir="$LAZARUS_DIR" \
  --os=win32 \
  --cpu=i386 \
  --compiler="$ROOT_DIR/tools/ppc386-win32-wrapper.sh" \
  "$ROOT_DIR/batrun.lpi"

echo "Built $ROOT_DIR/target/batrun.exe"
