# ASTRA 1.1.0 — LIVING PATHS

같은 배에서 깨어났지만, 우리는 서로 다른 목적지를 기억한다.
ASTRA의 탐사요원이 되어 승무원 사이에 숨은 **Null**을 찾는 싱글플레이 SF 사회추리 게임입니다.
사람과 이야기하고, 누구의 말이 어긋나는지 비교하고, 회의에서 따지고, 투표로 한 사람을 장기수면 포드에 재웁니다.

1.1.0은 1.0의 **내가 연결하는 사회추리** 위에 **내가 진실을 어떻게 다룰지 선택하는 플레이**를 얹습니다. 중요한 기록을 바로 공개할지 먼저 검증할지, 당사자에게 먼저 들려줄지 다른 출처로 확인할지, 세 곳 중 어디를 직접 볼지에 따라 다음 장면·정보 출처·사람의 반응·회의 맥락이 달라집니다. Canon과 Null 정답은 같은 seed에서 그대로입니다.

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

- **선택이 다음 장면을 바꿉니다.** DEAD_AIR / ECHO_WARD / RED_SHIFT / BORROWED_DAYS / THREE_MINUTES_DARK의 핵심 선택은 공개 범위, provenance, 개인 scene, meeting opener, 다음 Stage callback 중 둘 이상을 실제로 바꿉니다.
- **직접 본 것과 전해 들은 것이 다릅니다.** THREE_MINUTES_DARK에서 동력·통신·보안 중 한 곳만 DIRECT가 되고 나머지는 사람/기록을 통해 확인합니다.
- **다회차가 내 선택 때문에 달라집니다.** 선택형 micro-arc와 route callback은 첫 캠페인에 전부 쏟지 않으며, 같은 canon에 도달해도 다른 scene과 관계 texture를 볼 수 있습니다.
- **마지막 행동은 그대로, 받아들이는 방식은 누적됩니다.** share / wake / keep는 마지막 버튼이 정하지만, 캠페인에서 공개·검증·변호·잘못된 격리를 어떻게 했는지가 reception을 바꿉니다.
- **정보는 사람에게 있다.** 매일 생성되는 Day Packet의 목격·기록·전문 지식·전언은 각자 가진 사람만 압니다. 기록은 담당자가 열어 봐야 알 수 있고, 아무도 열지 않은 기록은 밤사이 지워질 수 있습니다.
- **대화는 한 번의 클릭으로.** 얼굴을 누르면 바로 대화가 시작되고, 아는 것에서 나온 질문 2~3개가 나옵니다. 같은 사실을 차분히 물을지 몰아붙일지도 고를 수 있습니다.
- **회의는 한 논점씩.** 누군가 꺼내고, 지목된 사람이 답하고, 제3자가 끼어든 뒤 멈춥니다. 그때 그 순간에 맞는 개입(재확인·되묻기·감싸기·기록 꺼내기·근거 묻기·지목)을 한 번 할 수 있습니다.
- **사람답게 판단한다.** 확신이 없는 사람은 믿는 사람(탐사요원 포함)의 말을 따르고, 인물마다 판단 습관과 약점이 다릅니다. Null도 원래 말투를 유지하며, 상황에 따라 다른 생존 방식을 씁니다.
- **어제가 오늘을 만든다.** 매일의 “오늘의 질문”, 어제의 투표와 밤에 대한 반응, 어제 지목당한 사람의 한마디가 이어집니다.

## 실행과 빌드

Windows: `ASTRA-1.1.0-windows.zip`을 풀고 `ASTRA/ASTRA.exe`를 실행합니다. 선택형 AI를 켜지 않으면 네트워크가 필요 없습니다.

소스에서:

```powershell
godot --headless --path . --import
godot --headless --path . --script res://tests/run_tests.gd -- --games=40   # ASTRA TESTS OK
godot --headless --path . --script res://tests/ui_smoke.gd                  # ASTRA UI SMOKE OK
powershell -File tools/build_windows.ps1 -Godot "C:\path\to\godot.exe"     # tests/ci_suite.txt 전체 + export + 부팅 검증 + zip
```

CI(`.github/workflows/godot-ci.yml`)와 Windows 빌드 스크립트는 같은 목록(`tests/ci_suite.txt`)을 실행합니다.
사람이 읽어야 하는 검증은 `tests/walkthrough_080.gd`(1~5 STAGE 대사 전문)와 `tests/visual_080.gd`(1366×768 · 1920×1080 화면)로 만듭니다.
