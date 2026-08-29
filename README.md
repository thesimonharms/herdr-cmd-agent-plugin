# herdr-cmd-agent-plugin

Herdr plugin to recognize [CommandCode](https://commandcode.ai) (`cmd`) as an agent.

Herdr tracks agent lifecycle (`idle` / `working` / `blocked`) via screen manifests and optional `HERDR_AGENT` process hints. This plugin ships a `cmd` screen manifest and installs it as a local Herdr override, so `cmd` panes get the same sidebar status, notifications, and `herdr agent` controls as built-in agents.

## What it adds

- `~/.config/herdr/agent-detection/cmd.toml` — idle/working/blocked rules for the `cmd` TUI
  - **idle**: `❯ Ask your question...` / `? for shortcuts` / `✻ Worked for …`
  - **working**: `esc to interrupt` + `◇ <verb>…` / braille spinners
  - **blocked**: `Do you trust the files in this folder?` and `Do you want to …?` permission prompts
- Herdr plugin actions to install, remove, and inspect the manifest
- Startup hook that re-installs the manifest on each Herdr launch (idempotent)

## Why `HERDR_AGENT=cmd` is required

`cmd` runs as `node` (`…/node_modules/command-code/dist/index.mjs`). Until Herdr ships native `cmd` process detection, Herdr cannot map that `node` process to the `cmd` manifest on its own. Set `HERDR_AGENT=cmd` on the wrapper command so Herdr uses this manifest for that pane:

```bash
HERDR_AGENT=cmd cmd
```

The plugin's detection rules and the `HERDR_AGENT` hint together give full `idle`/`working`/`blocked` coverage. Future Herdr releases may add native `cmd` process detection and make the hint unnecessary.

## Install

### Option A — as a Herdr plugin (recommended)

```bash
# from this repo checkout
herdr plugin link /home/simon/Projects/herdr-cmd-agent-plugin
# or from GitHub (after publishing)
herdr plugin install <owner>/herdr-cmd-agent-plugin --yes
```

The plugin's startup hook copies `agent-detection/cmd.toml` to `~/.config/herdr/agent-detection/cmd.toml` and reloads manifests. Manual control:

```bash
herdr plugin action invoke cmd.install-manifest
herdr plugin action invoke cmd.status
herdr plugin action invoke cmd.uninstall-manifest
herdr server agent-manifests  # verify `cmd  local  active 1.0.0`
```

### Option B — standalone (no plugin)

```bash
mkdir -p ~/.config/herdr/agent-detection
cp agent-detection/cmd.toml ~/.config/herdr/agent-detection/cmd.toml
herdr server reload-agent-manifests
herdr server agent-manifests  # should show `cmd  local  active 1.0.0`
```

## Usage

```bash
# every cmd session in Herdr
HERDR_AGENT=cmd cmd
HERDR_AGENT=cmd cmd "fix the failing tests" --trust
HERDR_AGENT=cmd cmd --resume

# handy alias (zsh/fish/bash)
alias cmd='HERDR_AGENT=cmd command cmd'

# verify detection in another pane
herdr pane process-info --pane w0:p1   # foreground should be "cmd" via HERDR_AGENT
herdr agent explain w0:p1 --verbose    # shows matched rule and state
herdr agent list                       # cmd panes appear with idle/working/blocked
```

`herdr agent start --kind cmd` is not yet supported by the Herdr binary (it validates `--kind` against a fixed list). Use `herdr pane split` + `herdr pane run` + `HERDR_AGENT=cmd cmd` instead. When Herdr adds native `cmd` kind support, `herdr agent start --kind cmd --pane <id>` will work.

## Files

```
herdr-plugin.toml               # plugin manifest (id=cmd, startup hook + actions)
agent-detection/cmd.toml        # screen manifest (the actual detection)
scripts/ensure-manifest.sh      # startup hook — idempotent install + reload
scripts/install.sh              # manual install action
scripts/uninstall.sh            # remove override + reload
scripts/status.sh               # show active manifest + hint
```

## Troubleshooting

- **Pane shows `unknown` or wrong agent** — ensure you used `HERDR_AGENT=cmd cmd`, not bare `cmd`. Check `herdr pane process-info --pane <id>` shows `cmd` as foreground.
- **Blocked prompt not detected** — run `herdr agent explain <pane> --verbose` while the prompt is visible and file an issue with the visible buffer.
- **Manifest not active** — `herdr server agent-manifests` should list `cmd  local  active 1.0.0`. If not, run `herdr server reload-agent-manifests` or restart Herdr.
- **After editing `cmd.toml`** — bump `version`, copy to `~/.config/herdr/agent-detection/cmd.toml`, then `herdr server reload-agent-manifests`.

## License

MIT
