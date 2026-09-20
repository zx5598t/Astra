param([string]$Godot = '')
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\godot_common.ps1"
try {
    $engine = Find-AstraGodot $Godot
    $version = (Get-Content -LiteralPath "$AstraRoot\VERSION" -Raw).Trim()
    $project = Get-Content -LiteralPath "$AstraRoot\project.godot" -Raw
    if ($project -notmatch ('config/version="' + [regex]::Escape($version) + '"')) { throw 'VERSION and project.godot disagree.' }
    $packageDir = Join-Path $AstraRoot 'build\ASTRA'
    $logDir = Join-Path $AstraRoot 'build\logs'
    New-Item -ItemType Directory -Path $packageDir, $logDir -Force | Out-Null
    Invoke-AstraGodot $engine @('--headless', '--path', $AstraRoot, '--import') "$logDir\import.log"
    Invoke-AstraGodot $engine @('--headless', '--path', $AstraRoot, '--script', 'res://tests/run_tests.gd', '--', '--games=40') "$logDir\rules.log" 'ASTRA TESTS OK'
    Invoke-AstraGodot $engine @('--headless', '--path', $AstraRoot, '--script', 'res://tests/campaign_tests.gd') "$logDir\campaign.log" 'ASTRA CAMPAIGN TESTS OK'
    Invoke-AstraGodot $engine @('--headless', '--path', $AstraRoot, '--script', 'res://tests/ui_smoke.gd') "$logDir\ui.log" 'ASTRA UI SMOKE OK'
    Invoke-AstraGodot $engine @('--headless', '--path', $AstraRoot, '--script', 'res://tests/redesign_tests.gd') "$logDir\redesign.log" 'ASTRA REDESIGN TESTS OK'
    Invoke-AstraGodot $engine @('--headless', '--path', $AstraRoot, '--script', 'res://tests/social_tests.gd') "$logDir\social.log" 'ASTRA SOCIAL TESTS OK'
    Invoke-AstraGodot $engine @('--headless', '--path', $AstraRoot, '--script', 'res://tests/replay_variety.gd') "$logDir\replay.log" 'ASTRA REPLAY VARIETY OK'
    Invoke-AstraGodot $engine @('--headless', '--path', $AstraRoot, '--script', 'res://tests/voyage_tests.gd') "$logDir\voyage.log" 'ASTRA VOYAGE TESTS OK'
    Invoke-AstraGodot $engine @('--headless', '--path', $AstraRoot, '--script', 'res://tests/stabilization_051_tests.gd') "$logDir\stabilization-051.log" 'ASTRA 0.5.1 STABILIZATION TESTS OK'
    Invoke-AstraGodot $engine @('--headless', '--path', $AstraRoot, '--script', 'res://tests/living_crew_052_tests.gd') "$logDir\living-crew-052.log" 'ASTRA 0.5.2 LIVING CREW TESTS OK'
    Invoke-AstraGodot $engine @('--headless', '--path', $AstraRoot, '--script', 'res://tests/living_crew_052_simulation.gd') "$logDir\simulation-052.log" 'ASTRA 0.5.2 SIMULATION OK'
    Invoke-AstraGodot $engine @('--headless', '--path', $AstraRoot, '--script', 'res://tests/story_consistency_tests.gd') "$logDir\story-consistency.log" 'ASTRA STORY CONSISTENCY TESTS OK'
    Invoke-AstraGodot $engine @('--headless', '--path', $AstraRoot, '--script', 'res://tests/content_audit.gd') "$logDir\content-audit.log" 'ASTRA CONTENT AUDIT OK'
    $exe = Join-Path $packageDir 'ASTRA.exe'
    Invoke-AstraGodot $engine @('--headless', '--path', $AstraRoot, '--export-release', 'Windows Desktop', $exe) "$logDir\export.log"
    if (-not (Test-Path -LiteralPath $exe)) { throw 'The Windows export did not produce ASTRA.exe.' }
    Invoke-AstraGodot $exe @('--headless', '--quit-after', '10', '--log-file', "$logDir\exported-game.log") "$logDir\exported-stdout.log"
    if ((Get-Content -LiteralPath "$logDir\exported-game.log" -Raw) -match 'SCRIPT ERROR|ERROR:') { throw 'The exported game failed its boot test.' }
    Copy-Item -LiteralPath "$AstraRoot\START_HERE.md", "$AstraRoot\LICENSES.md" -Destination $packageDir -Force
    $zip = Join-Path $AstraRoot "build\ASTRA-$version-windows.zip"
    $staging = Join-Path $AstraRoot 'build\package\ASTRA'
    New-Item -ItemType Directory -Path $staging -Force | Out-Null
    Copy-Item -LiteralPath $exe, "$packageDir\START_HERE.md", "$packageDir\LICENSES.md" -Destination $staging -Force
    Compress-Archive -LiteralPath $staging -DestinationPath $zip -Force
    $hash = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLowerInvariant()
    "$hash  $(Split-Path $zip -Leaf)" | Set-Content -LiteralPath "$zip.sha256" -Encoding ascii
    Write-Host "ASTRA WINDOWS BUILD OK: $zip"
} catch {
    Write-Host "[ASTRA] $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
