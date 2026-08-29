$ErrorActionPreference = "Stop"
$configDir = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { Join-Path $env:USERPROFILE ".config" }
$dest = Join-Path $configDir "herdr/agent-detection/cmd.toml"
if (Test-Path $dest) { Remove-Item $dest -Force; Write-Host "Removed $dest" } else { Write-Host "No override at $dest" }
$herdr = if ($env:HERDR_BIN_PATH) { $env:HERDR_BIN_PATH } else { "herdr" }
try { & $herdr server reload-agent-manifests; & $herdr server agent-manifests | Select-Object -First 20 } catch {}
