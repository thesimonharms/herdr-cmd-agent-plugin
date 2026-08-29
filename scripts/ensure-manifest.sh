#!/usr/bin/env sh
set -eu
# Idempotent startup hook: copy cmd.toml to Herdr config if missing or older.
# Herdr sets HERDR_PLUGIN_ROOT to the plugin directory; fall back to script dir.
PLUGIN_ROOT="${HERDR_PLUGIN_ROOT:-$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)}"
SRC="$PLUGIN_ROOT/agent-detection/cmd.toml"
DEST_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/herdr/agent-detection"
DEST="$DEST_DIR/cmd.toml"

if [ ! -f "$SRC" ]; then
  echo "ensure-manifest: source not found: $SRC" >&2
  exit 0
fi

mkdir -p "$DEST_DIR"

# If dest exists and is newer than src (user edited it), keep user's version.
if [ -f "$DEST" ] && [ "$DEST" -nt "$SRC" ]; then
  # Compare versions if possible; otherwise keep newer file.
  exit 0
fi

# Only copy when different to avoid unnecessary reloads.
if [ -f "$DEST" ] && cmp -s "$SRC" "$DEST" 2>/dev/null; then
  exit 0
fi

cp "$SRC" "$DEST"
echo "ensure-manifest: installed $DEST"

# Reload manifests in the running server if available.
HERDR_BIN="${HERDR_BIN_PATH:-herdr}"
if command -v "$HERDR_BIN" >/dev/null 2>&1; then
  "$HERDR_BIN" server reload-agent-manifests 2>/dev/null || true
fi
