# Shared by the source launcher and release builder. Paths may contain spaces.
$AstraRoot = Split-Path $PSScriptRoot -Parent
$AstraGodotVersion = '4.7.2'

function Find-AstraGodot([string]$Preferred = '') {
    $candidates = @($Preferred, $env:GODOT)
    $pathFile = Join-Path $AstraRoot 'godot_path.txt'
    if (Test-Path -LiteralPath $pathFile) {
        $candidates += (Get-Content -LiteralPath $pathFile -TotalCount 1).Trim().Trim('"')
    }
    foreach ($name in @('godot', 'godot4')) {
        $command = Get-Command $name -ErrorAction SilentlyContinue
        if ($command) { $candidates += $command.Source }
    }
    foreach ($folder in @("$env:USERPROFILE\Downloads", "$env:USERPROFILE\Desktop", "$env:LOCALAPPDATA\Programs", 'C:\Godot')) {
        if (Test-Path -LiteralPath $folder) {
            $candidates += @(Get-ChildItem -LiteralPath $folder -Filter 'Godot_v4.7.2*win64.exe' -File -Recurse -Depth 3 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName)
        }
    }
    foreach ($candidate in $candidates) {
        if (-not $candidate -or -not (Test-Path -LiteralPath $candidate)) { continue }
        if (Test-Path -LiteralPath $candidate -PathType Container) {
            $candidate = Get-ChildItem -LiteralPath $candidate -Filter '*win64.exe' -File | Select-Object -First 1 -ExpandProperty FullName
        }
        if (-not $candidate) { continue }
        $console = $candidate -replace '(?<!_console)\.exe$', '_console.exe'
        if (Test-Path -LiteralPath $console -PathType Leaf) { $candidate = $console }
        $version = & $candidate --version 2>&1
        if ($LASTEXITCODE -eq 0 -and "$version" -like "$AstraGodotVersion.stable*") { return $candidate }
    }
    throw "Godot $AstraGodotVersion Standard was not found. Install it, or put the full executable path in godot_path.txt. Players: https://github.com/zx5598t/Astra/releases/latest"
}

function Invoke-AstraGodot([string]$Executable, [string[]]$Arguments, [string]$LogPath, [string]$SuccessMarker = '') {
    # Windows PowerShell interprets native stderr as errors even for warnings.
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try { & $Executable @Arguments 2>&1 | Tee-Object -FilePath $LogPath | ForEach-Object { Write-Host "$_" }; $exitCode = $LASTEXITCODE }
    finally { $ErrorActionPreference = $oldPreference }
    $log = Get-Content -LiteralPath $LogPath -Raw
    if ($exitCode -ne 0 -or $log -match 'SCRIPT ERROR|Parse Error|Compile Error|Failed to load script|ERROR:') {
        throw "Godot failed. See $LogPath"
    }
    if ($SuccessMarker -and $log -notmatch [regex]::Escape($SuccessMarker)) { throw "Missing success marker '$SuccessMarker'. See $LogPath" }
}
