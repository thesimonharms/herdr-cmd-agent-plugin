$ErrorActionPreference = "Stop"
$pluginRoot = if ($env:HERDR_PLUGIN_ROOT) { $env:HERDR_PLUGIN_ROOT } else { Split-Path -Parent $PSScriptRoot }
$src = Join-Path $pluginRoot "agent-detection/cmd.toml"
$configDir = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { Join-Path $env:USERPROFILE ".config" }
$destDir = Join-Path $configDir "herdr/agent-detection"
$dest = Join-Path $destDir "cmd.toml"
if (!(Test-Path $src)) { throw "source not found: $src" }
if (!(Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
Copy-Item $src $dest -Force
Write-Host "Installed $dest"
$herdr = if ($env:HERDR_BIN_PATH) { $env:HERDR_BIN_PATH } else { "herdr" }
try {
  & $herdr server reload-agent-manifests
  & $herdr server agent-manifests | Select-String "cmd"
} catch { Write-Host "Restart Herdr to pick up the new manifest." }
Write-Host ""
Write-Host "Run as: `$env:HERDR_AGENT='cmd'; cmd"
