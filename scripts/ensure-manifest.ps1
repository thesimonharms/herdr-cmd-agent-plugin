$ErrorActionPreference = "Stop"
$pluginRoot = if ($env:HERDR_PLUGIN_ROOT) { $env:HERDR_PLUGIN_ROOT } else { Split-Path -Parent $PSScriptRoot }
$src = Join-Path $pluginRoot "agent-detection/cmd.toml"
$configDir = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { Join-Path $env:USERPROFILE ".config" }
$destDir = Join-Path $configDir "herdr/agent-detection"
$dest = Join-Path $destDir "cmd.toml"
if (!(Test-Path $src)) { Write-Host "source not found: $src"; exit 0 }
if (!(Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
if ((Test-Path $dest) -and ((Get-Item $dest).LastWriteTime -gt (Get-Item $src).LastWriteTime)) { exit 0 }
if ((Test-Path $dest) -and ((Get-Content $src -Raw) -eq (Get-Content $dest -Raw))) { exit 0 }
Copy-Item $src $dest -Force
Write-Host "installed $dest"
$herdr = if ($env:HERDR_BIN_PATH) { $env:HERDR_BIN_PATH } else { "herdr" }
try { & $herdr server reload-agent-manifests 2>$null } catch {}
