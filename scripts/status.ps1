$ErrorActionPreference = "Stop"
$configDir = if ($env:XDG_CONFIG_HOME) { $env:USERPROFILE; Join-Path $env:USERPROFILE ".config" } else { $env:XDG_CONFIG_HOME }
# fallback handled differently on pwsh
$configDir = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { Join-Path $HOME ".config" }
$dest = Join-Path $configDir "herdr/agent-detection/cmd.toml"
Write-Host "=== Herdr cmd detection status ==="
if (Test-Path $dest) { Write-Host "Local override: $dest"; Get-Content $dest | Select-Object -First 5 } else { Write-Host "Local override: (none)" }
$herdr = if ($env:HERDR_BIN_PATH) { $env:HERDR_BIN_PATH } else { "herdr" }
try { & $herdr server agent-manifests | Select-String "cmd" } catch { Write-Host "Herdr not on PATH" }
Write-Host "Process hint: run as `$env:HERDR_AGENT='cmd'; cmd"
