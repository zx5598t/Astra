# ASTRA 0.4.0 — 마지막 교신

고장 난 우주선, 여덟 승무원, 숨어 있는 Null.
장소를 조사하고 사람의 말을 대조해 누가 거짓말하는지 가려내는 싱글플레이 SF 사회추리 게임입니다.

**처음이라면** 그냥 실행하세요. 오프닝 1분, 교정 사건 10분이면 규칙을 다 배웁니다.

- [플레이 안내](START_HERE.md)
- [0.4.0에서 달라진 것](docs/RELEASE_NOTES.md)
- [왜 이렇게 만들었나](docs/WHY_CHANGED.md)
- [UX 감사](docs/UX_AUDIT_0.4.0.md) · [스토리 감사](docs/STORY_AUDIT_0.4.0.md) · [UI 규칙](docs/UI_STYLE_GUIDE_0.4.0.md)
- [자산 검토](docs/ASSET_AUDIT.md) · [추가로 필요한 이미지](docs/NEEDED_ASSETS.md)
- [검증 보고](docs/QA_REPORT.md)

## 실행

Windows 배포본 `ASTRA-0.4.0-windows.zip`을 **전부** 푼 뒤 `ASTRA.exe`를 실행합니다.
폴더 안의 `.pck` 파일이 exe와 같은 자리에 있어야 합니다.

## 개발

Godot **4.7.2 Standard**로 `project.godot`을 엽니다.
`run_astra.bat`이 엔진을 자동 탐색하며, 필요하면 `godot_path.txt`에 exe 전체 경로를 적습니다.

```powershell
godot --headless --path . --import
godot --headless --path . --script res://tests/run_tests.gd -- --games=40
godot --headless --path . --script res://tests/social_tests.gd
godot --headless --path . --script res://tests/replay_variety.gd
godot --headless --path . --script res://tests/campaign_tests.gd
godot --headless --path . --script res://tests/redesign_tests.gd
godot --headless --path . --script res://tests/ui_smoke.gd
```

같은 엔진 버전의 Windows export template를 설치한 뒤 `tools/build_windows.bat`으로
검증·내보내기·exe 부팅 검사를 수행합니다.
`tests/visual_qa.gd`는 실제 렌더러에서 1366×768 / 1920×1080 화면을 `build/qa`에 저장합니다.

## 구조

| 위치 | 내용 |
|---|---|
| `scripts/core/game_session.gd` | 한 사건의 규칙과 상태 전부 |
| `scripts/core/case_catalog.gd` | 사건 템플릿 (교정 1 + 캠페인 6) |
| `scripts/core/case_generator.gd` | 시드 → 숨은 진실 |
| `scripts/core/claim_ledger.gd` | 누가 무엇을 언제 말했는지 |
| `scripts/core/unlocks.gd` | 점진적 해금 |
| `scripts/core/codex.gd` | 3층 도움말 |
| `scripts/core/clue_help.gd` | 단서가 무슨 뜻인지 |
| `scripts/core/difficulty.gd` | 난이도 노브 |
| `scripts/ui/ui_kit.gd` | 모든 위젯의 출처 |
| `scripts/ui/views/` | 단계별 화면 |
| `assets/art031/` | 0.3.1 초상·배경·아이템 |
| `assets/art040/` | 0.4.0 누끼·도트·키아트 |

이미지 원본은 보존했으며 게임은 WebP를 사용합니다.

AI 대사 연기는 기본적으로 꺼져 있습니다. 전체 게임은 오프라인 동작하며,
선택 기능 사용법은 [backend/README.md](backend/README.md)에 있습니다.
