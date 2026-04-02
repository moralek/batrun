#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CFG_FILE="${BATRUN_FPC_WIN32_CFG:-$ROOT_DIR/target/fpc-win32.cfg}"
PPC386_BIN="${BATRUN_PPC386:-/tmp/fpc-i386-root/usr/lib/i386-linux-gnu/fpc/3.2.2/ppc386}"

if [[ ! -x "$PPC386_BIN" ]]; then
  echo "Win32 compiler not found: $PPC386_BIN" >&2
  echo "Run tools/write-fpc-win32-cfg.sh after restoring the Win32 toolchain." >&2
  exit 1
fi

if [[ ! -f "$CFG_FILE" ]]; then
  echo "Win32 compiler cfg not found: $CFG_FILE" >&2
  echo "Run tools/write-fpc-win32-cfg.sh first." >&2
  exit 1
fi

exec "$PPC386_BIN" -n @"$CFG_FILE" "$@"
