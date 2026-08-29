#!/usr/bin/env sh
set -eu
HERDR_BIN="${HERDR_BIN_PATH:-herdr}"
DEST="${XDG_CONFIG_HOME:-$HOME/.config}/herdr/agent-detection/cmd.toml"

echo "=== Herdr cmd detection status ==="
if [ -f "$DEST" ]; then
  echo "Local override: $DEST"
  head -n 5 "$DEST" 2>/dev/null || true
else
  echo "Local override: (none) — manifest not installed"
fi
echo ""
if command -v "$HERDR_BIN" >/dev/null 2>&1; then
  "$HERDR_BIN" server agent-manifests 2>&1 | grep -E "^  (cmd|last|result)" || "$HERDR_BIN" server agent-manifests --json 2>&1 | python3 -c "import json,sys; d=json.load(sys.stdin); m=[x for x in d['result']['manifests'] if x['agent']=='cmd']; print(json.dumps(m, indent=2) if m else 'no cmd manifest active')"
else
  echo "Herdr not on PATH"
fi
echo ""
echo "Process hint: run as HERDR_AGENT=cmd cmd (required until Herdr ships native cmd process detection)."
echo "Check a live pane: herdr pane process-info --pane <id> ; herdr agent explain <pane>"
