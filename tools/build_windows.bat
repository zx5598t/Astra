@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0build_windows.ps1" %*
if errorlevel 1 (
    pause
    exit /b 1
)
explorer "%~dp0..\build"
exit /b 0
