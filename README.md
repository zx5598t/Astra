# ASTRA 1.2.3 — CLEAR CURRENT

같은 배에서 깨어났지만, 우리는 서로 다른 목적지를 기억한다.
ASTRA의 탐사요원이 되어 승무원 사이에 숨은 **Null**을 찾는 싱글플레이 SF 사회추리 게임입니다.
사람과 이야기하고, 누구의 말이 어긋나는지 비교하고, 회의에서 따지고, 투표로 한 사람을 장기수면 포드에 재웁니다.

1.2.3은 **1.2.2 CROSSCURRENT의 공개/비공개 정보 경계를 바로잡고 Windows 배포 메타데이터를 정정하는 안정화 hotfix**입니다. Crosscurrent의 게임성은 유지하되, 플레이어만 알고 있던 비공개 투표 근거가 다음 날 NPC의 발언자·대사·2인 장면으로 새어 나오지 않게 막습니다.

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

- **비공개 근거는 방 전체의 기억이 되지 않습니다.** 플레이어 개인 노트에만 있던 ballot reason은 NPC-facing `REASON_FOLLOWUP`을 만들지 않고, 기존 저장에 남은 private residue도 source owner를 발언자로 승격하지 않습니다.
- **Windows 표시 버전도 실제 릴리스와 일치합니다.** EXE file/product version과 description을 1.2.3 / CLEAR CURRENT로 맞추고 회귀 테스트로 고정했습니다.
- **어제의 판단이 오늘 두 사람 사이에 남습니다.** 의미 있는 verdict residue가 있고 관련된 살아 있는 두 사람이 자연스러울 때만 짧은 Crosscurrent가 발생합니다.
- **둘이 자연스럽지 않으면 억지로 만들지 않습니다.** 해당 경우에는 1.2.1의 한 사람 verdict callback을 그대로 사용합니다.
- **플레이어가 한 번 개입합니다.** 판단 유지, 바뀐 근거 설명, 원출처/실제 순서 우선 확인 중 상황에 맞는 3개 선택이 즉시 반응과 오늘의 대화 lead, 회의 시작 맥락을 바꿉니다.
- **같은 내용을 겹쳐 말하지 않습니다.** Crosscurrent가 재생된 날은 기존 generic verdict callback과 VERDICT 재질문을 생략하고, Past Echo가 회의에서 더 직접적인 현재 맥락이면 그 opener를 우선합니다.
- **캐릭터가 자기 방식으로 움직입니다.** 노아는 원본과 사본, 세나는 출입 순서, 소렌은 원음, 루칸은 경로, 마렌은 흔적의 지속성처럼 기존 전문성을 행동과 대사에 사용합니다.
- **표정은 역할 힌트가 아닙니다.** calm / warm / tense / uneasy 기존 표현만 공개 상황과 플레이어 선택에 따라 사용하며 Null 여부는 후보·유형·표정 결정에 쓰지 않습니다.
- **정답과 밸런스는 그대로입니다.** Crosscurrent는 truth, Day Packet, required proof, 기본 evidence, action count를 바꾸지 않습니다.
- **저장 형식도 그대로입니다.** 새 dedup/choice/priority는 기존 `flags["stage_080"]`의 optional state로 들어가며 Meta v12 / Snapshot v4를 유지합니다.

## 실행과 빌드

Windows: `ASTRA-1.2.3-windows.zip`을 풀고 `ASTRA/ASTRA.exe`를 실행합니다. 선택형 AI를 켜지 않으면 네트워크가 필요 없습니다.

소스에서:

```powershell
godot --headless --path . --import
godot --headless --path . --script res://tests/run_tests.gd -- --games=40   # ASTRA TESTS OK
godot --headless --path . --script res://tests/ui_smoke.gd                  # ASTRA UI SMOKE OK
powershell -File tools/build_windows.ps1 -Godot "C:\path\to\godot.exe"     # tests/ci_suite.txt 전체 + export + 부팅 검증 + zip
```

CI(`.github/workflows/godot-ci.yml`)와 Windows 빌드 스크립트는 같은 목록(`tests/ci_suite.txt`)을 실행합니다.
사람이 읽어야 하는 검증은 `tests/walkthrough_100.gd` + `tests/walkthrough_110.gd`와 Windows `tests/visual_100.gd`로 만듭니다. 1.2.1은 Verdict Residue 회귀 gate를 추가하고 Past Echo·History variation·dialogue exposure를 포함한 기존 전체 QA를 그대로 유지합니다.
