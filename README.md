# ASTRA 0.5.0 — 마지막 교신

같은 배에서 깨어났지만, 우리는 서로 다른 목적지를 기억한다.
ASTRA의 탐사요원으로서 배를 살피고, 동료의 말과 기록을 비교하는 싱글플레이 SF 미스터리입니다.

처음에는 미라·준·다렌·노아 네 명만 깨어 있습니다. 이동, 대화, 주변 조사를 통해 첫 각성을 마칩니다. 첫 장에는 격리 투표나 점수 시험이 없습니다. 이후 세나·소렌·루칸·마렌이 차례로 합류하고, 공개 회의와 추리가 깊어집니다.

- [플레이 안내](START_HERE.md)
- [변경 사항](docs/RELEASE_NOTES.md)
- [설계와 저장 호환](docs/GAME_DESIGN.md)
- [요청사항 구현 추적](docs/IMPLEMENTATION_0.5.0.md)
- [인물 설정](docs/CHARACTERS.md) · [이미지 출처와 변환](docs/ASSET_AUDIT.md)
- [검증 결과](docs/QA_REPORT.md)

## 실행

`build/ASTRA-0.5.0-windows.zip`의 압축을 풀고 `ASTRA/ASTRA.exe`를 실행합니다. 리소스가 실행 파일에 포함되어 있습니다. 네트워크와 AI 설정 없이 플레이할 수 있습니다.

소스는 Godot **4.7.2 Standard**에서 `project.godot`을 열거나 `run_astra.bat`으로 실행합니다. 기존 작업 폴더 이름 `ASTRA-0.4.0`은 유지했으며 프로젝트와 Windows 파일 버전은 0.5.0입니다.

## 검증 및 빌드

```powershell
godot --headless --path . --import
godot --headless --path . --script res://tests/run_tests.gd -- --games=40
godot --headless --path . --script res://tests/voyage_tests.gd
powershell -File tools/build_windows.ps1 -Godot "C:\path\to\godot.exe"
```

빌드 스크립트는 규칙·캠페인·UI·사회관계·반복성·탐색 회귀 검사를 통과한 뒤 Windows 실행 파일을 내보내고 직접 부팅합니다. GitHub 공개, 커밋, 태그는 별도 작업입니다.
