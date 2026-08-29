#!/usr/bin/env sh
set -eu
DEST_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/herdr/agent-detection"
DEST="$DEST_DIR/cmd.toml"
HERDR_BIN="${HERDR_BIN_PATH:-herdr}"

if [ -f "$DEST" ]; then
  rm -f "$DEST"
  echo "Removed $DEST"
else
  echo "No override at $DEST"
fi

if command -v "$HERDR_BIN" >/dev/null 2>&1; then
  "$HERDR_BIN" server reload-agent-manifests 2>&1 || true
  "$HERDR_BIN" server agent-manifests 2>&1 | head -n 20 || true
fi
