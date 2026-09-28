# ASTRA 1.2.0 — AFTERIMAGE

같은 배에서 깨어났지만, 우리는 서로 다른 목적지를 기억한다.
ASTRA의 탐사요원이 되어 승무원 사이에 숨은 **Null**을 찾는 싱글플레이 SF 사회추리 게임입니다.
사람과 이야기하고, 누구의 말이 어긋나는지 비교하고, 회의에서 따지고, 투표로 한 사람을 장기수면 포드에 재웁니다.

1.2.0은 이전 History에서 **직접 겪고 선택한 정보가 다음 History의 조사 순서를 바꾸는** 업데이트입니다. [잔향] 질문은 실제 과거 route history가 있을 때만 열리며 정답·Null 역할·미래 정보를 주지 않습니다. 대신 현재 History에서 누구에게 무엇을 먼저 확인할지, 어떤 기록을 먼저 열지, 그 정확함을 NPC가 어떻게 받아들이는지가 달라집니다.

- [플레이 안내](START_HERE.md) · [변경 사항](CHANGELOG.md) · [릴리스 노트](docs/RELEASE_NOTES.md)
- [설계](docs/GAME_DESIGN.md) · [인물](docs/CHARACTERS.md) · [스토리 원장](docs/STORY_LEDGER_080.md) · [검증](docs/QA_REPORT.md)
## 구조

| | 인원 | Null | 특징 |
|---|---|---|---|
| PART I — STAGE 1~4 | 4 → 5 → 6 → 7명 (세나·소렌·루칸 순서로 합류) | 1명 | 프로토콜 없음, 밤은 자동 진행 |
| PART II — STAGE 5~13 | 8명 (마렌 합류) | 2명 | 가디언(5) · 애널리스트(6) · 엠패스(7) 중 하나를 이야기 속에서 선택 |

하루(DAY): **아침 → 대화 → 회의 → 투표 → 밤**. 매일 정확히 한 사람이 포드로 가고, 기권은 없습니다.
Null을 모두 재우면 승리, Null 쪽 표가 나머지와 같아지거나 탐사요원이 밤에 쓰러지면 실패입니다.
STAGE가 끝나면 배의 기록이 다시 맞춰지고(재동기화) 모두가 다시 깨어납니다. 기억하는 사람은 탐사요원뿐입니다.

## 이번 버전의 핵심

- **지난 History가 이번 질문을 바꿉니다.** 10개의 [잔향] 기회를 RED_SHIFT부터 THRESHOLD까지 8개 Stage에 분산했습니다. Stage 번호만 높다고 열리지 않고, 플레이어가 실제로 선택한 과거 route가 route_history에 있어야 합니다.
- **잔향은 정답 버튼이 아닙니다.** 현재 NPC가 원래 가지고 있던 기록·목격·전문 소견의 확인 순서만 앞당기거나 특별 질문과 반응을 만듭니다. Null 정답, hidden truth, 미래 Stage 정보는 사용하지 않습니다.
- **NPC가 정확한 선행지식을 이상하게 봅니다.** 지나치게 정확한 질문에 대한 반응은 새 의심 게이지 대신 기존 trust/bond/relationship feedback을 사용합니다.
- **후반 History가 실제로 다르게 보입니다.** 같은 seed의 진실과 기본 evidence를 유지한 채 과거 route에 따라 질문·반응·확인 방식이 달라집니다.
- **마렌과 루칸의 전문성이 플레이에 직접 들어옵니다.** 마렌은 생장·환경·관리 주기의 연속성을, 루칸은 실제 이동 가능 시간·위험·경로를 읽습니다. 잔향을 쓴 날의 회의에서는 일반 도입 한 줄을 이 전문성 해석으로 교체해 회의 길이를 늘리지 않습니다.
- **대사 반복 선택을 게임 RNG와 분리했습니다.** 같은 기능 문장이 가까운 간격으로 반복되는 문제를 줄이되 사건·거짓말·스트레스·투표에 쓰는 기존 gameplay RNG는 건드리지 않습니다.
- **기존 1.1.1의 강점은 그대로입니다.** 다섯 branch anchor, 8개 micro-arc/20개 선택, Link, fairness, SHARE/WAKE/KEEP, WARM/CAUTIOUS/STRAINED, 범용 release workflow를 유지합니다.
- **저장 형식은 그대로입니다.** 새 상태는 기존 voyage dictionary의 optional field로 들어가므로 Meta v12 / Snapshot v4를 유지하고 1.1.1 저장은 안전하게 기본값으로 hydrate합니다.
## 실행과 빌드

Windows: `ASTRA-1.2.0-windows.zip`을 풀고 `ASTRA/ASTRA.exe`를 실행합니다. 선택형 AI를 켜지 않으면 네트워크가 필요 없습니다.

소스에서:

```powershell
godot --headless --path . --import
godot --headless --path . --script res://tests/run_tests.gd -- --games=40   # ASTRA TESTS OK
godot --headless --path . --script res://tests/ui_smoke.gd                  # ASTRA UI SMOKE OK
powershell -File tools/build_windows.ps1 -Godot "C:\path\to\godot.exe"     # tests/ci_suite.txt 전체 + export + 부팅 검증 + zip
```

CI(`.github/workflows/godot-ci.yml`)와 Windows 빌드 스크립트는 같은 목록(`tests/ci_suite.txt`)을 실행합니다.
사람이 읽어야 하는 검증은 `tests/walkthrough_100.gd` + `tests/walkthrough_110.gd`와 Windows `tests/visual_100.gd`로 만듭니다. 1.2는 Past Echo·History variation·dialogue exposure report도 기존 1.1 QA와 함께 `build/qa` artifact로 보존합니다.
