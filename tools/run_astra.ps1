param([ValidateSet('Play', 'Editor', 'Check')][string]$Mode = 'Play')
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\godot_common.ps1"
try {
    if ($Mode -eq 'Play' -and (Test-Path -LiteralPath "$AstraRoot\ASTRA.exe")) {
        Start-Process -FilePath "$AstraRoot\ASTRA.exe" -WorkingDirectory $AstraRoot
        exit 0
    }
    $engine = Find-AstraGodot
    if ($Mode -eq 'Check') { Write-Output $engine; exit 0 }
    $logDir = Join-Path $AstraRoot 'build\logs'
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    Write-Host '[ASTRA] Preparing source assets...'
    Invoke-AstraGodot $engine @('--headless', '--path', $AstraRoot, '--import') (Join-Path $logDir 'source-import.log')
    $arguments = @('--path', ('"' + $AstraRoot + '"'))
    if ($Mode -eq 'Editor') { $arguments += '--editor' }
    $guiEngine = $engine -replace '_console\.exe$', '.exe'
    if (-not (Test-Path -LiteralPath $guiEngine)) { $guiEngine = $engine }
    Start-Process -FilePath $guiEngine -ArgumentList $arguments -WorkingDirectory $AstraRoot
} catch {
    Write-Host "[ASTRA] $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
