#!/usr/bin/env sh
set -eu
PLUGIN_ROOT="${HERDR_PLUGIN_ROOT:-$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)}"
SRC="$PLUGIN_ROOT/agent-detection/cmd.toml"
DEST_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/herdr/agent-detection"
DEST="$DEST_DIR/cmd.toml"
HERDR_BIN="${HERDR_BIN_PATH:-herdr}"

if [ ! -f "$SRC" ]; then
  echo "install: source not found: $SRC" >&2
  exit 1
fi
mkdir -p "$DEST_DIR"
cp "$SRC" "$DEST"
echo "Installed $DEST"

if command -v "$HERDR_BIN" >/dev/null 2>&1; then
  echo "Reloading Herdr agent manifests..."
  "$HERDR_BIN" server reload-agent-manifests 2>&1 || true
  echo "Active manifests:"
  "$HERDR_BIN" server agent-manifests 2>&1 | grep -E "cmd|agent" || true
else
  echo "Herdr not on PATH — restart Herdr to pick up the new manifest."
fi

cat <<'EOF'

Next: run cmd with the HERDR_AGENT hint so Herdr maps the node process to cmd:

  HERDR_AGENT=cmd cmd

Or add an alias to your shell:

  alias cmd='HERDR_AGENT=cmd cmd'

Without the hint, Herdr sees "node" instead of "cmd" and cannot apply this manifest.
EOF
