@echo off
chcp 65001 >nul
setlocal EnableExtensions EnableDelayedExpansion
title ASTRA 실행기
cd /d "%~dp0"

rem ------------------------------------------------------------------
rem  ASTRA 실행기
rem  1) GODOT 환경 변수  2) godot_path.txt  3) PATH의 godot
rem  4) 다운로드/바탕화면/문서/Programs 폴더에서 Godot_v4.*_win64.exe 검색
rem  실행:  run_astra.bat          게임 실행
rem         run_astra.bat --editor Godot 에디터로 열기
rem         run_astra.bat --check  Godot 위치만 확인
rem ------------------------------------------------------------------

set "GODOT_EXE="
if defined GODOT if exist "%GODOT%" set "GODOT_EXE=%GODOT%"

if not defined GODOT_EXE if exist "godot_path.txt" (
    set /p GODOT_EXE=<"godot_path.txt"
    set "GODOT_EXE=!GODOT_EXE:"=!"
    if not exist "!GODOT_EXE!" set "GODOT_EXE="
)

if not defined GODOT_EXE (
    for %%N in (godot.exe godot4.exe) do (
        if not defined GODOT_EXE (
            for /f "delims=" %%P in ('where %%N 2^>nul') do if not defined GODOT_EXE set "GODOT_EXE=%%P"
        )
    )
)

if not defined GODOT_EXE (
    for %%D in ("%USERPROFILE%\Downloads" "%USERPROFILE%\Desktop" "%USERPROFILE%\Documents" "%LOCALAPPDATA%\Programs" "C:\Godot") do (
        if not defined GODOT_EXE if exist "%%~D" (
            for /f "delims=" %%P in ('dir /b /s /a-d /o-n "%%~D\Godot_v4*_win64.exe" 2^>nul') do if not defined GODOT_EXE set "GODOT_EXE=%%P"
        )
    )
)

if not defined GODOT_EXE (
    echo.
    echo  [ASTRA] Godot 4.7 을 찾지 못했습니다.
    echo.
    echo   1. 열리는 페이지에서 Godot 4.7.x Windows Standard 버전을 받으세요.
    echo   2. 압축을 풀고, 이 폴더에 godot_path.txt 파일을 만들어
    echo      Godot_v4.7.x-stable_win64.exe 의 전체 경로를 한 줄로 적으세요.
    echo      예: C:\Users\나\Downloads\Godot_v4.7.2-stable_win64.exe
    echo   3. run_astra.bat 을 다시 실행하세요.
    echo.
    start "" "https://godotengine.org/download/windows/"
    pause
    exit /b 1
)

echo  [ASTRA] Godot: !GODOT_EXE!
if /i "%~1"=="--check" exit /b 0

if not exist ".godot\imported" (
    echo  [ASTRA] 첫 실행 준비 중입니다. 에셋을 가져오는 데 1분 정도 걸릴 수 있습니다...
    "!GODOT_EXE!" --headless --path "%~dp0." --import >nul 2>&1
)

if /i "%~1"=="--editor" (
    start "" "!GODOT_EXE!" --editor --path "%~dp0."
) else (
    start "" "!GODOT_EXE!" --path "%~dp0."
)
exit /b 0
