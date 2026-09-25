param([Parameter(ValueFromRemainingArguments=$true)][string[]]$GodotArgs)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/godot_common.ps1"
$engine = Find-AstraGodot
# Regression scripts never touch the player's real saves or editor settings.
$localData = Join-Path $AstraRoot 'build/test-user'
New-Item -ItemType Directory -Path $localData -Force | Out-Null
$previousAppData = $env:APPDATA
try {
    $env:APPDATA = $localData
    & $engine @GodotArgs
    exit $LASTEXITCODE
} finally { $env:APPDATA = $previousAppData }
