@echo off
chcp 65001 >nul
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0.."

rem  Windows용 ASTRA.exe를 build\ASTRA 폴더에 만듭니다.
rem  필요: Godot 4.7.2 + 같은 버전의 Export Templates - 에디터 메뉴의 내보내기 템플릿 관리에서 설치

call run_astra.bat --check >nul 2>&1
if errorlevel 1 (
    echo  [ASTRA] Godot을 찾지 못했습니다. 먼저 run_astra.bat 을 실행해 안내를 따라 주세요.
    pause
    exit /b 1
)
for /f "tokens=2,*" %%A in ('call run_astra.bat --check') do set "GODOT_EXE=%%B"

if not exist ".godot\imported" "!GODOT_EXE!" --headless --path . --import >nul 2>&1
if not exist "build\ASTRA" mkdir "build\ASTRA"
echo  [ASTRA] 내보내는 중...
"!GODOT_EXE!" --headless --path . --export-release "Windows Desktop" "build\ASTRA\ASTRA.exe"
if not exist "build\ASTRA\ASTRA.exe" (
    echo  [ASTRA] 내보내기에 실패했습니다. Export Templates 4.7.2 가 설치되어 있는지 확인하세요.
    pause
    exit /b 1
)
echo  [ASTRA] 완료: build\ASTRA\ASTRA.exe
explorer "build\ASTRA"
exit /b 0
