# ASTRA 0.5.4 — AFTERMATH

같은 배에서 깨어났지만, 우리는 서로 다른 목적지를 기억한다.  
ASTRA의 탐사요원으로서 기록과 현장을 확인하고, 반복될 때마다 조금씩 달라지는 여덟 동료의 관계와 행동을 읽는 싱글플레이 SF 사회추리 미스터리입니다.

0.5.4는 0.5.3 HEARTBEAT의 Living Crew 기반을 유지하면서, 승무원이 실제로 하루를 보내는 Crew Routine과 선택 뒤에 남는 Consequence Chain을 플레이 흐름에 연결합니다. 평소 위치와 행동을 알아야 deviation을 눈치챌 수 있고, 중요한 선택은 즉시/지연/다음 날/다음 루프의 작은 후속으로 돌아옵니다. 미라는 Emotional Anchor를 유지하지만 이번 확장의 중심은 여덟 명 전원의 생활과 결과입니다.

- [플레이 안내](START_HERE.md)
- [0.5.4 변경 사항](docs/RELEASE_NOTES.md)
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

아직 배우지 않은 시스템은 미리 전부 보여 주지 않습니다. 0.5.4의 Routine/Consequence/Micro-Arc도 본격 노출을 ECHO WARD 이후에 두며, CALIBRATION에는 routine narration을 추가하지 않아 첫 30분의 필수 텍스트량을 늘리지 않습니다.

## Living Crew

NPC의 중요한 행동은 가능한 한 “왜”가 남습니다.

- 관계는 trust / comfort / respect / tension / protectiveness 다섯 축과 관계 태그를 사용합니다.
- 캐릭터마다 baseline, stress response, lie style이 있으며 평소와 다른 중요한 행동에는 deviation reason이 붙습니다.
- NPC는 실제로 알고 있는 정보만 말하거나 판단할 수 있습니다. 정보 공유는 player → NPC, NPC → NPC, public 경로와 provenance를 기록합니다.
- 투표 화면은 한 표씩 공개하며 NPC가 왜 그 대상을 골랐는지 자연어 이유를 함께 표시합니다.
- 무고한 진술 차이는 EMBARRASSMENT / PROTECT_OTHER / HIDE_MISTAKE / KEEP_PROMISE / PERSONAL_SECRET / FEAR / MISREMEMBERED 등으로 나뉩니다. MISREMEMBERED는 거짓말 판정이 아닙니다.
- 루프마다 social theme, 작은 hook, 관계/기억 변화가 일부 달라집니다. RNG가 대사를 쓰지는 않습니다.

## AFTERMATH 콘텐츠

현재 authored voyage/reactive scene library는 **537개**입니다.

| 인물 | authored scene |
|---|---:|
| 미라 | **88** |
| 준 | 72 |
| 다렌 | 66 |
| 노아 | 70 |
| 세나 | 63 |
| 소렌 | 55 |
| 루칸 | 53 |
| 마렌 | 70 |

0.5.4 신규 authored scene은 **64개**입니다. 8명 × 4-beat micro-arc 32개와 routine/reaction/pair/opinion 장면 32개로 구성되며, 소렌과 루칸은 각각 10개의 신규 장면으로 더 보강했습니다.

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

0.5.4 release branch는 Godot **4.7.2 stable**에서 Linux/Windows를 함께 검증합니다.

주요 0.5.4 전용 게이트:

- Mira content / agency / phrase audit
- storylet unseen weighting / rare-event pity / multi-line coherence
- autonomous crew active-state invariant
- explicit NPC knowledge propagation
- player/NPC relationship callback
- 기존 1,000 conversation + 1,000 meeting + 500-loop simulation
- 새 player-visible 500-loop HEARTBEAT simulation
- 첫판/전체 캠페인/저장 호환/UI smoke
- Windows export + 실제 exported `ASTRA.exe` boot

최근 검증 기준 player-visible 500-loop 결과는 visible signature **500/500**, Mira optional exposure 평균 **2.50** / 최대 **4**, autonomous event **27종**, 0.5.3 scene coverage **65.4%**, rare event 즉시 반복 **0회**였습니다.

## 실행과 빌드

정식 0.5.4 Windows 후보의 파일명은 다음과 같습니다.

`ASTRA-0.5.4-windows.zip`

압축을 풀고 `ASTRA/ASTRA.exe`를 실행합니다. 리소스는 실행 파일에 포함되며 선택형 AI를 켜지 않으면 네트워크 연결이 필요하지 않습니다.

소스 실행:

```powershell
godot --headless --path . --import
godot --headless --path . --script res://tests/run_tests.gd -- --games=40
godot --headless --path . --script res://tests/mira_content_tests.gd
godot --headless --path . --script res://tests/heartbeat_053_simulation.gd
godot --headless --path . --script res://tests/content_audit.gd
powershell -File tools/build_windows.ps1 -Godot "C:\path\to\godot.exe"
```

GitHub Actions의 `release/*` 브랜치는 Windows export template을 설치해 실제 ZIP/SHA-256을 만들고, 내보낸 EXE를 직접 부팅한 뒤에만 release candidate job을 통과시킵니다.
