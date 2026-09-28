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
    # The same suite CI runs (tests/ci_suite.txt): script | marker | extra args.
    foreach ($row in Get-Content -LiteralPath "$AstraRoot\tests\ci_suite.txt") {
        if ($row -match '^\s*(#|$)') { continue }
        $parts = $row.Split('|')
        $script = $parts[0]
        $marker = $parts[1]
        $arguments = @('--headless', '--path', $AstraRoot, '--script', "res://tests/$script")
        if ($parts.Length -gt 2 -and $parts[2] -ne '') { $arguments += @('--') + $parts[2].Split(' ') }
        Invoke-AstraGodot $engine $arguments "$logDir\$($script.Replace('.gd','')).log" $marker
    }
    $exe = Join-Path $packageDir 'ASTRA.exe'
    Invoke-AstraGodot $engine @('--headless', '--path', $AstraRoot, '--export-release', 'Windows Desktop', $exe) "$logDir\export.log"
    if (-not (Test-Path -LiteralPath $exe)) { throw 'The Windows export did not produce ASTRA.exe.' }

    # Verify the metadata Windows Explorer actually reads from the exported PE,
    # not only the source export preset. This keeps patch releases from shipping
    # a stale file/product version or previous codename.
    $expectedWinVersion = "$version.0"
    $presetText = Get-Content -LiteralPath "$AstraRoot\export_presets.cfg" -Raw
    $descriptionMatch = [regex]::Match($presetText, 'application/file_description="([^"]+)"')
    if (-not $descriptionMatch.Success) { throw 'Windows file_description is missing from export_presets.cfg.' }
    $expectedDescription = $descriptionMatch.Groups[1].Value
    $versionInfo = (Get-Item -LiteralPath $exe).VersionInfo
    $actualFileVersion = ([string]$versionInfo.FileVersion).Trim()
    $actualProductVersion = ([string]$versionInfo.ProductVersion).Trim()
    $actualDescription = ([string]$versionInfo.FileDescription).Trim()
    if ($actualFileVersion -ne $expectedWinVersion) {
        throw "ASTRA.exe FileVersion mismatch: expected $expectedWinVersion, got $actualFileVersion"
    }
    if ($actualProductVersion -ne $expectedWinVersion) {
        throw "ASTRA.exe ProductVersion mismatch: expected $expectedWinVersion, got $actualProductVersion"
    }
    if ($actualDescription -ne $expectedDescription) {
        throw "ASTRA.exe FileDescription mismatch: expected '$expectedDescription', got '$actualDescription'"
    }
    Write-Host "ASTRA WINDOWS FILE VERSION: $actualFileVersion"
    Write-Host "ASTRA WINDOWS PRODUCT VERSION: $actualProductVersion"
    Write-Host "ASTRA WINDOWS FILE DESCRIPTION: $actualDescription"

    Invoke-AstraGodot $exe @('--headless', '--quit-after', '10', '--log-file', "$logDir\exported-game.log") "$logDir\exported-stdout.log"
    if ((Get-Content -LiteralPath "$logDir\exported-game.log" -Raw) -match 'SCRIPT ERROR|ERROR:') { throw 'The exported game failed its boot test.' }
    Copy-Item -LiteralPath "$AstraRoot\START_HERE.md", "$AstraRoot\LICENSES.md" -Destination $packageDir -Force
    $zip = Join-Path $AstraRoot "build\ASTRA-$version-windows.zip"
    $staging = Join-Path $AstraRoot 'build\package\ASTRA'
    New-Item -ItemType Directory -Path $staging -Force | Out-Null
    Copy-Item -LiteralPath $exe, "$packageDir\START_HERE.md", "$packageDir\LICENSES.md" -Destination $staging -Force
    Compress-Archive -LiteralPath $staging -DestinationPath $zip -Force
    $hash = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLowerInvariant()
    $zipSize = (Get-Item -LiteralPath $zip).Length
    "$hash  $(Split-Path $zip -Leaf)" | Set-Content -LiteralPath "$zip.sha256" -Encoding ascii
    Write-Host "ASTRA WINDOWS ZIP SIZE: $zipSize bytes"
    Write-Host "ASTRA WINDOWS SHA256: $hash"
    Write-Host "ASTRA WINDOWS BUILD OK: $zip"
} catch {
    Write-Host "[ASTRA] $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
