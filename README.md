# ASTRA 0.5.0 — Living Crew

같은 배에서 깨어났지만, 우리는 서로 다른 목적지를 기억한다.
ASTRA의 탐사요원으로서 배를 살피고, 동료의 말과 기록을 비교하는 싱글플레이 SF 미스터리입니다.

처음에는 미라·준·다렌·노아 네 명만 깨어 있습니다. 첫 접속(CALIBRATION)은 의료실 한 곳에서
전원 패널을 확인하고 미라와 직접 이야기하는 짧은 도입입니다. 회의·격리 투표·밤 행동은 처음부터
한꺼번에 나오지 않고 캠페인을 진행하면서 차례로 열립니다.

- [플레이 안내](START_HERE.md)
- [0.5.0 변경 사항](docs/RELEASE_NOTES.md)
- [설계와 저장 호환](docs/GAME_DESIGN.md)
- [인물 설정](docs/CHARACTERS.md)
- [이미지 출처와 변환](docs/ASSET_AUDIT.md)
- [검증 결과](docs/QA_REPORT.md)

## 실행

GitHub Actions의 release-candidate 또는 정식 Release에 있는
`ASTRA-0.5.0-windows.zip`의 압축을 풀고 `ASTRA/ASTRA.exe`를 실행합니다.
리소스는 실행 파일에 포함되며 네트워크나 AI 설정 없이 플레이할 수 있습니다.

소스는 Godot **4.7.2 Standard**에서 `project.godot`을 열거나
`run_astra.bat`으로 실행합니다. 프로젝트와 Windows 파일 버전은 0.5.0입니다.

## 0.5.0 진행 구조

- **CALIBRATION** — 전원 패널 + 미라와의 직접 대화. 회의/투표/밤 없음.
- **DEAD AIR** — 조사와 대화에 집중.
- **GLASS GARDEN** — 짧은 공개 확인 도입.
- **ECHO WARD** — 장기수면 격리 투표와 첫 밤 행동 도입.
- 이후 장 — 감시·휴식, 더 깊은 회의와 관계/기억 변화가 단계적으로 확장.

탐색용 authored scene은 280개이며, 개인 이벤트 40개와 핵심 관계 8쌍의 전용 장면,
3인 대화가 포함되어 있습니다.

## 검증 및 빌드

```powershell
godot --headless --path . --import
godot --headless --path . --script res://tests/run_tests.gd -- --games=40
godot --headless --path . --script res://tests/story_consistency_tests.gd
godot --headless --path . --script res://tests/content_audit.gd
powershell -File tools/build_windows.ps1 -Godot "C:\path\to\godot.exe"
```

GitHub Actions는 Linux 전체 검증과 별도로 Windows 가상 PC에서 Godot 4.7.2를 직접 실행합니다.
`release/*` 브랜치에서는 Windows export template까지 설치해 실제 ZIP과 SHA-256을 생성합니다.
