@echo off
setlocal
cd /d "%~dp0"
set "ASTRA_MODE=Play"
if /i "%~1"=="--editor" set "ASTRA_MODE=Editor"
if /i "%~1"=="--check" set "ASTRA_MODE=Check"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\run_astra.ps1" -Mode %ASTRA_MODE%
if errorlevel 1 (
    if /i not "%~1"=="--check" pause
    exit /b 1
)
exit /b 0
