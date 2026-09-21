# ASTRA 0.5.7 — CLEAR SIGNAL

같은 배에서 깨어났지만, 우리는 서로 다른 목적지를 기억한다.  
ASTRA의 탐사요원으로서 기록과 현장을 확인하고, 반복될 때마다 조금씩 달라지는 여덟 동료의 관계와 행동을 읽는 싱글플레이 SF 사회추리 미스터리입니다.

0.5.7 CLEAR SIGNAL은 새 시스템과 새 장면을 더 쌓는 대신, 이미 있는 608개의 authored voyage/reactive scene이 **한 번의 loop에서 덜 겹치고 더 선명하게 이어지도록** 선택 흐름을 정리한 업데이트입니다. 플레이어가 이미 본 중요한 스레드는 이어지기 쉬워지고, 관련 없는 새 고중요도 스레드는 한꺼번에 여러 개 열리지 않도록 soft weight로 억제합니다.

Mandatory/progression, 실제 FOLLOWUP·consequence, 현재 보이는 continuation, 명시적으로 고른 topic과 pinned question은 이 예산을 우회합니다. 숨은 Null 정보나 motive, raw relationship 수치는 selector에 넣지 않으며 save schema는 v10을 그대로 유지합니다. 신규 authored voyage scene은 **0개**이고 전체 library는 **608개**를 유지합니다.

- [플레이 안내](START_HERE.md)
- [0.5.7 변경 사항](docs/RELEASE_NOTES.md)
- [설계와 저장 호환](docs/GAME_DESIGN.md)
- [인물 설정](docs/CHARACTERS.md)
- [이미지 출처와 변환](docs/ASSET_AUDIT.md)
- [검증 결과](docs/QA_REPORT.md)

## 처음 플레이

처음에는 미라·준·다렌·노아 네 명만 깨어 있습니다. 첫 접속 **CALIBRATION**은 의료실 한 곳에서 전원 패널을 확인하고 미라와 직접 이야기하는 짧은 도입입니다.

- CALIBRATION — 전원 패널 + 미라와 직접 대화. 회의/투표/밤 없음.
- DEAD AIR — 조사와 대화에 집중.
- GLASS GARDEN — 짧은 공개 확인 도입. 세나와 준이 중심.
- ECHO WARD — 소렌의 신호, 첫 장기수면 격리 투표와 밤 행동.
- SILENT ORBIT — 루칸과 19년 전 도착 기록.
- RED SHIFT — 마렌과 출항보다 오래된 시료.
- LAST LIGHT — 기록과 사람에 대한 판단이 합쳐지는 후반.

아직 배우지 않은 시스템은 미리 전부 보여 주지 않습니다. 0.5.7에서도 기존 Routine/Consequence/Micro-Arc는 본격 노출을 ECHO WARD 이후에 두며, CALIBRATION에는 routine narration을 추가하지 않아 첫 30분의 필수 텍스트량을 늘리지 않습니다.

## CLEAR SIGNAL — 서사 초점 회복

- 한 loop의 player-visible high-salience 새 스레드는 보통 **2~3개** 안에서 움직이도록 soft budget을 적용합니다.
- 이미 보인 authored chain의 continuation, due FOLLOWUP/consequence, mandatory/progression은 새 스레드로 세지 않습니다.
- 세 번째 unrelated FOCUS family부터 가중치를 낮추고 네 번째 이후는 예외적으로만 나타나게 하지만, hard cap으로 막지는 않습니다.
- explicit topic과 직접 연결된 pinned question은 계속 찾아갈 수 있습니다.
- 같은 화자에게 optional scene이 몰리면 speaker exposure 가중치를 낮춥니다. 미라는 ECHO WARD 이후 optional exposure 최대 **4회**를 그대로 지킵니다.
- dense loop에서는 두 번째 autonomous beat를 버리지 않고 뒤로 미룹니다.
- content audit의 대형 library 경고는 런타임 500-loop gate로 대체하고, 반복 opener 경고는 실제 scene ID/speaker/action을 출력합니다.

500-loop 실제 플레이 경로 검증 결과는 high-salience distinct family 평균 **2.22**, P95 **3**, 최대 **4**, 4개 이상 unrelated thread **11/500**입니다. continuation **10회**, zero-meaningful 연속 **0**, visible signature **500/500**, autonomous unique **23**, 0.5.3 authored coverage **59.3%**, rare immediate repeat **0**, Mira optional max **4**를 기록했습니다.

## Living Crew

NPC의 중요한 행동은 가능한 한 “왜”가 남습니다.

- 관계는 trust / comfort / respect / tension / protectiveness 다섯 축과 관계 태그를 사용합니다.
- 캐릭터마다 baseline, stress response, lie style이 있으며 평소와 다른 중요한 행동에는 deviation reason이 붙습니다.
- NPC는 실제로 알고 있는 정보만 말하거나 판단할 수 있습니다. 정보 공유는 player → NPC, NPC → NPC, public 경로와 provenance를 기록합니다.
- 투표 화면은 한 표씩 공개하며 NPC가 왜 그 대상을 골랐는지 자연어 이유를 함께 표시합니다.
- 무고한 진술 차이는 EMBARRASSMENT / PROTECT_OTHER / HIDE_MISTAKE / KEEP_PROMISE / PERSONAL_SECRET / FEAR / MISREMEMBERED 등으로 나뉩니다. MISREMEMBERED는 거짓말 판정이 아닙니다.
- 루프마다 social theme, 작은 hook, 관계/기억 변화가 일부 달라집니다. RNG가 대사를 쓰지는 않습니다.

## ECHOES — 읽히는 여파와 승무원 기록

- 같은 pair/day/axis의 작은 관계 변화는 합쳐서 보여 주고, 의미 없는 미세 변화는 숨깁니다.
- 밤은 즉시 consequence, 다음 날 briefing은 관계/판단의 지속 여파를 맡아 같은 문장을 연속 화면에서 반복하지 않습니다.
- Crew Archive에는 STABLE 14 / OBSERVED 10 / ECHO 8, 총 **32개** observation이 있으며 8명 모두 4개씩입니다.
- OBSERVED/ECHO는 실제 scene 또는 visible relationship milestone을 본 경우에만 해금합니다.
- CALIBRATION에서는 observation을 정상 저장하되 연속 Codex 토스트는 띄우지 않습니다.
- save schema는 **v10**이며 v9/legacy 저장은 안전하게 hydrate하고, resume 뒤 동일 Codex를 새 기록으로 다시 보고하지 않습니다.

현재 authored voyage/reactive scene library는 **608개**입니다.

| 인물 | authored scene |
|---|---:|
| 미라 | **98** |
| 준 | 81 |
| 다렌 | 74 |
| 노아 | 79 |
| 세나 | 71 |
| 소렌 | 64 |
| 루칸 | 62 |
| 마렌 | 79 |

0.5.5 신규 authored/reactive scene은 **71개**입니다. Personal Motive 25 / Cooperative Investigation 18 / Foreknowledge reaction 8 / post-arrival canon record 4 / incident follow-up 8 / delegation report 8로 구성됩니다. 소렌과 루칸은 cooperative observation을 한 개씩 더 받아 중후반 전문성을 보강했습니다.

Routine baseline은 **36개의 정상 활동**, **27개의 authored deviation 상황**, **10개의 reason tag**를 사용합니다. 한 loop/day의 눈에 띄는 deviation은 최대 3개로 제한하고, ECHO는 loop 0에서 나오지 않으며 NULL_ACTIVITY는 실제 Null에게만 허용합니다.

Consequence authored event는 **23개**입니다: IMMEDIATE 4 / DELAYED 8 / NEXT_DAY 7 / NEXT_LOOP 4. 후속은 숫자 보상 대신 장면·메모·관계·다음 행동으로 돌아옵니다.

기존 autonomous crew beat는 **27개**를 유지합니다.

## Crew Routine & Consequences

승무원은 플레이어를 기다리는 버튼이 아니라 이미 자기 일을 하고 있습니다. 플레이어가 직접 목격한 중요한 routine deviation만 Notebook의 **직접 본 변화**에 남습니다.

여덟 명은 각각 하나의 대표 micro-arc를 가집니다: 미라의 자기 방치, 준의 작은 실수, 다렌의 실패한 모델, 노아의 개인 사본, 세나의 과잉 보호, 소렌의 청취 피로, 루칸의 위험 경로, 마렌의 표본 보존입니다. 한 loop에서 모두 보여 주지 않습니다.

Notebook의 질문 하나는 **집중해서 확인**할 수 있습니다. 정답 위치를 알려 주지 않고 관련 사람/방/storylet의 선택 가중치만 조금 올립니다.

## Notebook

Notebook은 정답표가 아니라 기억 보조입니다.

- **지금 궁금한 것**: 현재 중요한 질문 최대 3개
- **확인한 사실**: 플레이어가 실제로 발견한 내용
- **정보 공유**: 최근 정보의 “알고 있음 / 아직 비공개 또는 공개됨”
- **지난 기록과 달라진 점**: 이미 플레이어가 발견한 변화만 요약
- Character Note: 직접 경험한 성격·습관·현재 관계 관찰

게임이 “준이 Null일 확률 67%”처럼 자동 추론하지는 않습니다.

## 검증

0.5.7 CLEAR SIGNAL 구현 기준 검증은 Godot **4.7.2 stable**에서 Linux/Windows 모두 GREEN입니다.

- Linux import / 전체 GDScript parse clean
- 전체 모델: **45,301 checks**, 40 games 기준 TOTAL smart **68%** / random **0%** / passive **0%**
- 기존 0.5.1~0.5.5 regression 유지
- Codex 0.5.6: **95 checks**
- ECHOES 0.5.6: **33 checks**
- CLEAR SIGNAL 0.5.7 invariants: **47 checks**
- CLEAR SIGNAL 500-loop runtime exposure: **10 checks**
- Windows UI smoke / main-scene boot 성공
- 1366×768 / 1920×1080 핵심 UI 접근성 smoke 유지
- authored scene audit: **608개**, 캐릭터별 98 / 81 / 74 / 79 / 71 / 64 / 62 / 79

정식 0.5.7 Windows CI artifact는 `ASTRA-0.5.7-windows.zip`이며 최종 검증 SHA-256은 `a9d1bdb0959c9d2dd3a51953daed48e8d146a7e33d17a1de862e1579d0a2f48b`입니다.

## 실행과 빌드

정식 0.5.7 Windows 후보의 파일명은 다음과 같습니다.

`ASTRA-0.5.7-windows.zip`

압축을 풀고 `ASTRA/ASTRA.exe`를 실행합니다. 리소스는 실행 파일에 포함되며 선택형 AI를 켜지 않으면 네트워크 연결이 필요하지 않습니다.

소스 실행:

```powershell
godot --headless --path . --import
godot --headless --path . --script res://tests/run_tests.gd -- --games=40
godot --headless --path . --script res://tests/codex_056_tests.gd
godot --headless --path . --script res://tests/echoes_056_tests.gd
godot --headless --path . --script res://tests/clear_signal_057_tests.gd
godot --headless --path . --script res://tests/clear_signal_057_simulation.gd
godot --headless --path . --script res://tests/content_audit.gd
powershell -File tools/build_windows.ps1 -Godot "C:\path\to\godot.exe"
```

GitHub Actions의 `release/*` 브랜치는 Windows export template을 설치해 실제 ZIP/SHA-256을 만들고, 내보낸 EXE를 직접 부팅한 뒤에만 release candidate job을 통과시킵니다.
