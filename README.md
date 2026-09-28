# ASTRA 1.2.1 — WEIGHT OF WORDS

같은 배에서 깨어났지만, 우리는 서로 다른 목적지를 기억한다.
ASTRA의 탐사요원이 되어 승무원 사이에 숨은 **Null**을 찾는 싱글플레이 SF 사회추리 게임입니다.
사람과 이야기하고, 누구의 말이 어긋나는지 비교하고, 회의에서 따지고, 투표로 한 사람을 장기수면 포드에 재웁니다.

1.2.1은 **회의에서 한 말과 투표 이유가 다음 날 사람들의 반응과 질문에 남는** 업데이트입니다. 새 평판 점수를 추가하지 않고, 이미 있던 공개 지목·변호·Link·증거·투표 이유를 연결해 “내 판단이 투표 버튼에서 끝나지 않는다”는 감각을 만듭니다.

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

- **투표 이유가 다음 날까지 남습니다.** Link·모순·증거를 이유로 골랐다면 당시 플레이어가 실제로 알던 source/provenance와 함께 기록됩니다.
- **공개 발언과 실제 표를 함께 봅니다.** 지목→같은 대상 투표, 변호→끝까지 비투표, 공개 발언과 다른 표를 구분합니다.
- **새 근거 뒤의 판단 변경을 따로 봅니다.** 공개된 Link·evidence·confession 뒤에 생각을 바꾼 경우를 단순 reversal과 구분합니다.
- **다음 아침에 최대 한 번 짧게 되돌아옵니다.** 관련 승무원이 어제의 판단을 언급하고, 그 사람이 오늘의 대화 lead가 될 수 있습니다.
- **후속 질문은 정답 버튼이 아닙니다.** 어제 이미 알던 근거를 다시 해석할 뿐 새 proof·Null 역할·hidden truth를 만들지 않습니다.
- **캐릭터마다 확인 방식이 다릅니다.** 노아는 출처/원본, 세나는 절차/출입, 소렌은 원출처, 루칸은 경로 가능성, 마렌은 흔적의 지속성을 우선합니다.
- **새 평판 meter와 추가 투표 클릭이 없습니다.** 기존 trust/bond, ballot UX, meeting pacing, fairness와 1.2.0 Past Echo를 그대로 보호합니다.
- **저장 형식도 그대로입니다.** Meta v12 / Snapshot v4를 유지하고 새 residue/dedup은 기존 stage state의 optional data로 저장됩니다.

## 실행과 빌드

Windows: `ASTRA-1.2.1-windows.zip`을 풀고 `ASTRA/ASTRA.exe`를 실행합니다. 선택형 AI를 켜지 않으면 네트워크가 필요 없습니다.

소스에서:

```powershell
godot --headless --path . --import
godot --headless --path . --script res://tests/run_tests.gd -- --games=40   # ASTRA TESTS OK
godot --headless --path . --script res://tests/ui_smoke.gd                  # ASTRA UI SMOKE OK
powershell -File tools/build_windows.ps1 -Godot "C:\path\to\godot.exe"     # tests/ci_suite.txt 전체 + export + 부팅 검증 + zip
```

CI(`.github/workflows/godot-ci.yml`)와 Windows 빌드 스크립트는 같은 목록(`tests/ci_suite.txt`)을 실행합니다.
사람이 읽어야 하는 검증은 `tests/walkthrough_100.gd` + `tests/walkthrough_110.gd`와 Windows `tests/visual_100.gd`로 만듭니다. 1.2.1은 Verdict Residue 회귀 gate를 추가하고 Past Echo·History variation·dialogue exposure를 포함한 기존 전체 QA를 그대로 유지합니다.
