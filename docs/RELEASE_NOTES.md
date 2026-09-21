# ASTRA 0.5.5 — FAULT LINES

## Why did they do that?

0.5.4에서 “이 사람이 평소와 다르다”를 만들었다면 0.5.5의 중심 질문은 **“왜?”**다. 준이 기록을 숨겼다면 sabotage일 수도 있지만 자기 실수를 감추려는 것일 수도 있다. 노아의 비공개 사본은 조작일 수도 있고 원본 보존일 수도 있다. 미라가 의료 기록을 공개하지 않는 행동도 누군가를 보호하는 이유와 Null 여부를 분리해서 읽어야 한다.

## Personal Motives

11종 motive vocabulary를 사용하고 캐릭터별 compatible motive를 제한한다. 한 loop에서 1~3명의 일부 NPC에게만 배정되며 Null과 독립이다. UI에는 시스템명·상태·확률을 보여 주지 않는다. 직접 목격 / 기록 / 진술처럼 여러 작은 흔적을 겹쳐 이유를 좁힌다.

## Dynamic Ship Incidents

중후반에 **8종**의 작은 함선 incident가 기존 action economy 안에서 발생한다. 전투/미니게임/실시간 타이머가 아니라 안전·정보·시간·사람 중 무엇을 먼저 둘지 선택하게 한다. 한 loop에 최대 1건이다.

## Cooperative Investigation & Delegation

기존 “같이 갈래?” companion 기능을 실제 조사 결과에 연결했다. core fact는 누구와 가도 같고 secondary observation만 전문성에 따라 달라진다. SILENT ORBIT 이후에는 optional 조사 하나를 동료에게 맡길 수 있으며, 보고는 그 NPC의 관점으로 요약되고 TESTIMONY source로 남는다.

## Loop Foreknowledge

loop > 0이면서 과거에 실제 같은 incident를 겪었을 때만 선행 대응 선택이 열린다. 먼저 막으면 위험을 줄일 수 있지만 원래 발생했을 기록을 잃을 수 있다. NPC도 플레이어가 미래를 아는 듯 움직인 사실에 반응한다.

## Repeat Compression & Momentum

seen count가 2 이상이고 새 fact/choice/consequence/motive/relationship 변화가 없는 compressible 장면만 짧게 줄인다. **장면 전체 보기**를 항상 제공한다. 의미 있는 신규 콘텐츠를 오래 못 본 memory는 다음 loop의 unseen meaningful storylet 가중치에 반영한다.

## Information Source Quality

Notebook에 확률 대신 **직접 확인 / 기록 / 진술 / 전해 들음**을 표시한다. source type은 truth가 아니다. 기록도 틀릴 수 있고 목격도 불완전할 수 있다.

## Story hook

SILENT ORBIT 이후 평범한 post-arrival 업무 기록을 최대 1~2개 발견할 수 있다. 새 canon은 “ASTRA가 도착한 뒤에도 한동안 정상적인 활동이 있었다”까지다. 목적지 정체, loop 원인, ASTRA AI, Null 본질은 확정하지 않는다.

## Content & release

0.5.5 신규 authored/reactive scene: **71**  
전체 voyage/reactive library: **608**  
신규 분배: 미라 10 / 준 9 / 다렌 8 / 노아 9 / 세나 8 / 소렌 9 / 루칸 9 / 마렌 9

Windows artifact: `ASTRA-0.5.5-windows.zip` + `.sha256`.

---

# ASTRA 0.5.4 — AFTERMATH

## Routines & Consequences

0.5.4는 “살아 있는 승무원”을 “하루를 사는 승무원”으로 한 단계 더 밀어 붙인다. 동료는 플레이어가 말을 걸기 전에도 자기 장소에서 자기 일을 하고, 평소 공간·활동 baseline에서 벗어날 때는 내부 reason을 갖는다. 그 변화는 범인 표시가 아니라 플레이어가 “왜?”라고 묻게 하는 약한 단서다.

전체 authored voyage/reactive scene은 **537개**다. 0.5.4 신규 장면은 **64개**이며 캐릭터별 총량은 미라 88 / 준 72 / 다렌 66 / 노아 70 / 세나 63 / 소렌 55 / 루칸 53 / 마렌 70이다.

## Crew Routine

정상 routine은 총 **36개 활동**, authored routine deviation은 **27개 상황**, reason tag는 **10종**이다. CALIBRATION/DEAD AIR의 visible deviation은 0, GLASS GARDEN은 최대 1, 이후는 최대 1~3개다. ECHO는 loop 0에서 나오지 않고 NULL_ACTIVITY는 실제 Null만 사용할 수 있다.

기존 autonomous crew beat 27개는 유지하며 Routine과 연결한다.

## Eight Micro-Arcs

- Mira — Self Neglect
- Jun — Mistake
- Daren — Failed Model
- Noa — Private Copy
- Sena — Overprotection
- Soren — Listening Fatigue
- Lucan — Risk Route
- Maren — Save One Sample

각 arc는 4 beat이며 한 loop에 전부 나오지 않고 main story gate도 아니다.

## Consequence Chains

authored consequence event는 **23개**다: IMMEDIATE 4 / DELAYED 8 / NEXT_DAY 7 / NEXT_LOOP 4. 후속은 +trust/-trust 알림이 아니라 이후 장면, memory tag, 기록 공개 순서, 관계 태도, 다음 날 로그, 다음 loop residue로 나타난다. consequence stage는 일반 storylet selector가 선택보다 먼저 뽑지 못하게 gate했다.

## Social Deduction Legibility

전날과 표가 달라졌다면 DecisionTrace의 strongest reason을 이용해 new_evidence / relationship_change / memory_change / uncertainty로 구분한다. 개표 화면에는 **지난 투표와 달라짐 · 이전 → 현재 · 이유**가 짧게 보이며, opinion trace에는 해당 NPC의 known facts와 qualitative relationship context가 남는다.

## Curiosity Pin

Notebook의 열린 질문 중 최대 1개를 **집중해서 확인**할 수 있다. 관련 사람/방/storylet의 가중치만 조금 올리고 정답 위치나 Null 확률은 보여 주지 않는다.

## First 30 Minutes

CALIBRATION에는 Routine 설명문도 표시하지 않는다. 본격 Routine/Consequence/Micro-Arc는 ECHO WARD 이후에 체감되도록 해 첫 30분 복잡도를 다시 늘리지 않았다.

## QA / Release Gate

0.5.4 전용 게이트는 Routine 1,000-day simulation, 8 micro-arc, consequence timing/queue/expiry/next-loop carry, meaningful-choice audit, Curiosity pin, decision-legibility report, save migration, AFTERMATH 500-loop, 5/20-loop human-readable editorial report다. 기존 1,000 conversation / 1,000 meeting / 500-loop Living Crew와 Windows export + exported ASTRA.exe boot도 유지한다.

Windows artifact: ASTRA-0.5.4-windows.zip + .sha256.

---
# ASTRA 0.5.3 — HEARTBEAT

## Familiar stranger

0.5.3의 목표는 새 시스템 숫자를 늘리는 것이 아니라 0.5.2에서 만든 Living Crew 시스템을 플레이어가 실제로 느끼게 하는 것이다. NPC가 자기 할 말만 하는 대신 앞선 행동과 관계를 기억하고, 같은 사람을 다음 loop에서 만났을 때 조금 익숙하고 조금 낯설게 보이도록 했다.

미라는 이번 버전의 **Emotional Anchor**다. 처음 만나는 의무관이라는 위치를 이용해 반복의 감정을 가장 깊게 보여 주지만, 정식 romance route·plot armor·항상 플레이어 편인 성격은 만들지 않았다. 미라는 Null이 될 수 있고, 격리될 수 있고, 플레이어에게 실망하거나 플레이어를 의심할 수 있다. 다른 동료의 chapter spotlight와 전문 분야도 그대로 유지한다.

## Mira Emotional Anchor

미라 authored speaker scene은 **80개**다. 0.5.3에서 CARE / DAILY / MEDICAL / PLAYER / RELATIONSHIP / ECHO / CONFLICT 장면을 추가했고 private event pool은 **13개**가 됐다.

반복 motif는 차, 체온/손목 센서, 의료실 의자·담요, 피아노, 컵처럼 작은 생활 요소를 사용한다. 이전 loop를 직접 기억한다고 말하지 않고 같은 컵 위치나 음악 볼륨, 익숙한 붕대 위치처럼 행동이 먼저 달라진다.

플레이어와의 관계 tone은 WARM / PROFESSIONAL / STRAINED로 표현할 수 있다. 같은 상태 확인 장면도 관계와 conflict echo에 따라 문장이 달라진다. player behavioral profile의 evidence_first / people_first / protective / skeptical / secretive / confrontational / patient도 미라 반응에 연결된다.

약속은 HUD quest가 아니다. “다치면 말하기” 같은 일부 선택은 dialogue memory에만 남고, 지키거나 어겼을 때 나중 장면이 자연스럽게 돌아올 수 있다.

미라가 세계를 독점하지 않도록 ECHO WARD 이후 일반 loop의 optional Mira scene은 최대 4개로 제한한다. 자동 시뮬레이션에서 평균 노출은 **2.50**, 최대 **4**였다.

## Living Dialogue

전체 authored voyage/reactive scene은 **473개**다.

- 미라 80
- 준 65
- 다렌 59
- 노아 63
- 세나 56
- 소렌 45
- 루칸 43
- 마렌 62

0.5.3 신규 authored scene은 **81개**다. Mira 전용 pack 27개, 다른 일곱 명의 player/relationship callback 28개, pair/trio social scene 26개로 구성했다.

여러 사람이 말하는 0.5.3 scene에는 line relation을 기록해 다음 줄이 reply / clarify / challenge / support / proposal / agreement / inference 등 어떤 방식으로 앞 말을 받는지 audit한다. 단순 독백 나열을 새 콘텐츠로 세지 않는다.

기존 pair 장면은 상대가 반드시 현재 같은 방에 있어야 해서 노출률이 낮았는데, 이제 이미 만났고 활동 중이며 scene context가 맞는 동료는 authored storylet에 자연스럽게 합류할 수 있다.

## Autonomous Crew

새 `AstraCrewActivityModel`에는 **27개의 autonomous beat**가 있다. 하루/loop마다 모두 강제로 보여 주지 않고 조건에 맞는 0~2개만 예정한다.

예를 들어 미라는 세나의 붕대를 갈고, 준은 기관실을 수리하고, 노아와 다렌은 기록을 비교하고, 소렌과 루칸은 신호와 좌표를 맞춘다. 플레이어가 그 방에 들어오면 이미 진행 중인 장면을 목격할 수 있고, 일부는 overheard 선택으로 끼어들기 / 듣기 / 지나가기가 가능하다.

DEAD AIR에는 autonomous text를 추가하지 않았고 GLASS GARDEN도 최대 1개만 허용해 초반 텍스트 부하를 유지했다.

## Knowledge / Decision

NPC 지식은 계속 명시적으로 추적한다. 플레이어가 발견한 fact, 특정 NPC에게만 보여 준 fact, 공개된 fact를 구분한다.

0.5.3은 NPC→NPC 전파를 추가했다. Noa → Soren처럼 실제 전달이 발생해야 Soren이 알 수 있고, 그 뒤 Soren → Lucan이 일어나기 전까지 Lucan은 그 사실을 사용할 수 없다. 전파 경로는 provenance에 남는다.

Notebook에는 최근 정보에 대해 **알고 있음: 나 / 노아 · 아직 비공개** 정도의 가벼운 표시만 제공한다. 권한표나 숫자 UI로 만들지는 않았다.

중요한 vote/meeting/share 행동은 DecisionTrace를 유지한다. 투표 화면은 기존처럼 각 NPC의 표 아래에 자연어 이유를 표시하며, 0.5.3의 autonomous 정보 공유도 업무/안전상 필요 같은 이유와 source fact를 trace에 남긴다.

## Storylet selection과 replay

`AstraStoryletScheduler`는 authored content만 선택한다.

- 아직 보지 못한 scene을 약간 우대
- 최근 family 반복 억제
- social theme의 중심 pair에 작은 가중치
- rare/uncommon 조건을 여러 번 만족했는데 못 본 경우 내부 pity 증가
- 본 뒤 pity reset

pity 수치는 UI에 표시하지 않는다. 메인 story progression을 특별 이벤트 RNG에 묶지도 않는다.

player-visible 500-loop simulation 결과:

- visible signatures: **500 / 500**
- Mira optional exposure: 평균 **2.50**, 최대 **4**
- autonomous event coverage: **27종**
- relationship pair coverage: **21**
- 0.5.3 authored scene coverage: **65.4%**
- rare scene immediate repeat: **0**

## Notebook과 질문

Curiosity Question 문구를 시스템 목표가 아니라 플레이어가 실제로 궁금해할 문장으로 다듬었다.

예:
- “미라가 기억하는 지구 귀환 기록은 어디에서 왔나?”
- “세나와 준은 정말 예전부터 알던 사이였나?”
- “19년이 맞다면 왜 우리 몸은 그 시간을 지나지 않은 것처럼 보일까?”

Notebook의 **지금 궁금한 것**은 최대 3개만 보여 준다. OPEN / PARTIAL / ANSWERED / CHANGED를 사용하며, 다음 loop에서 전제가 바뀌면 이미 해결했다고 생각했던 질문이 CHANGED로 다시 열릴 수 있다.

## 첫 30분과 기존 spotlight

CALIBRATION 필수 대사량은 늘리지 않았다. DEAD AIR에도 0.5.3 autonomous event를 넣지 않았다. 대부분의 새 Living Dialogue는 ECHO WARD 이후에 집중한다.

GLASS GARDEN의 세나·준, ECHO WARD의 소렌, SILENT ORBIT의 루칸, RED SHIFT의 마렌 spotlight는 유지한다. 미라는 각 chapter를 연결하는 감정 축이지 모든 mystery의 설명자가 아니다.

## QA와 Windows

0.5.3 전용 검증:

- Mira content / agency / phrase / forced-romance audit
- WARM / PROFESSIONAL / STRAINED response regression
- Mira Null / isolation regression
- storylet unseen weighting / rare pity
- multi-line dialogue coherence metadata
- autonomous active-state and budget tests
- explicit knowledge propagation A→B→C
- pair defense / player behavior / promise callback
- player-visible 500-loop HEARTBEAT simulation

기존 1,000 conversation / 1,000 meeting / 500-loop Living Crew simulation과 첫판·캠페인·저장·UI 회귀도 그대로 유지한다.

검증 기준점에서는 Windows Godot 4.7.2 import, 모든 모델/콘텐츠 테스트, UI smoke, Windows release-candidate export, **exported ASTRA.exe boot**까지 통과했다. 최종 0.5.3 VERSION으로 다시 같은 파이프라인을 실행한 결과와 ZIP/SHA-256은 `docs/QA_REPORT.md`에 기록한다.

---

# ASTRA 0.5.0 — Living Crew

## 첫판: 한 번에 하나씩 배우는 구조

첫 실행은 설명창 대신 세 장면으로 시작한다. 탐사요원과 네 명의 승무원이 깨어 있다는 사실, 포드 기록의 실행자 서명이 비었다는 사실만 먼저 보여 준다. CALIBRATION에서는 전원 패널을 한 번 확인하고 미라와 직접 이야기하면 된다. 준·노아·다렌은 패널 확인 장면에서 자연스럽게 합류하므로 네 사람을 하나씩 찾아 누를 필요가 없다.

캠페인의 시스템은 단계적으로 열린다. DEAD AIR는 조사와 대화, GLASS GARDEN은 짧은 공개 확인, ECHO WARD부터 장기수면 격리 투표와 밤 행동을 사용한다. 아직 배우지 않은 단계는 브리핑과 상단 진행 표시에서도 보이지 않는다.

## 살아 있는 승무원 규칙과 장기수면 격리

발언·투표·보호·선택 대상은 모두 같은 ACTIVE 참가자 목록에서 나온다. 생체 신호가 끊겼거나 장기수면 격리된 승무원은 어떤 경로로도 다시 발언하거나 투표할 수 없고, 자기 자신에게 투표할 수도 없다. 모델 마지막 단계에서 다시 검증하므로 UI 우회로도 막는다.

'격리'는 사망이 아니다. 최다 득표자는 사건이 끝날 때까지 장기수면 포드로 이동하며 행동·회의·투표에서 빠진다. 화면의 상태도 **활동 중 / 장기수면 격리 / 생체 신호 두절**로 분리했다. 개표에서는 각 NPC가 왜 그 대상을 골랐는지 짧은 이유를 함께 보여 준다.

## 연결된 회의와 대화 피드백

회의는 모든 사람이 알리바이를 차례로 읊는 방식에서 벗어나 몇 개의 논점만 실제 대화로 연출한다. 누군가 모순이나 의혹을 제기하면 지목된 사람이 바로 답하고, 화면에는 '새 논점' 또는 '직전 발언에 대한 답'이 표시된다. 전체 알리바이와 주장은 보이지 않는 것이 아니라 Claim Ledger에 그대로 남아 노트에서 비교할 수 있다.

자동 진행은 기본적으로 꺼져 있고, 켠 경우에도 중요한 발언에서는 멈춘다. 멈춘 이유와 계속 버튼이 화면에 나타나므로 고장처럼 보이지 않는다.

심문에서는 숨은 신뢰/긴장 수치 대신 결과를 질적으로 알려 준다. 증거 제시·모순 지적·안심·압박 뒤에 **납득함, 흔들림, 아직 저항함, 불확실, 화남** 중 하나가 즉시 표시된다.

## 캐릭터와 관계 콘텐츠

탐색용 작성 장면은 170개에서 **280개**로 확장했다. 캐릭터별 장면 수는 28~36개로 동일하게 맞추지 않았고, 생활 습관·직무·관계·기억 반응을 서로 다르게 배분했다.

준-세나, 미라-마렌, 다렌-노아, 소렌-루칸, 준-다렌, 세나-미라, 마렌-다렌, 노아-소렌 등 핵심 8쌍에는 최소 2개 이상의 전용 관계 장면을 추가했다. 세 사람이 동시에 반응하는 장면도 4개 추가했다.

개인 이벤트는 캐릭터당 1개에서 **4~6개, 총 40개**로 늘었다. 날짜·신뢰·긴장도에 따라 후보가 달라져 같은 사람도 다른 상황에서 다른 개인 장면을 보여 준다.

새로 깨어나는 세나·소렌·루칸·마렌의 첫 장면도 주변 승무원이 함께 반응하도록 다시 작성해, 캐릭터 소개가 독립된 한 줄 대사가 아니라 이미 존재하는 관계 속에서 시작되도록 했다.

## 밤 행동

ECHO WARD의 첫 밤은 **사람 보호 / 기록 백업** 두 선택으로 시작한다. 감시 행동은 다음 단계에서 열리고, 휴식은 후반 챕터에서만 등장한다. 첫 밤 화면은 각 행동이 무엇을 막거나 남기는지 짧게 설명한다.

## 검증과 Windows

0.5.0은 테스트가 통과해야만 배포할 수 있다. 기존 규칙·저장 호환·UI smoke·사회추리·반복 플레이·항해 검증에 더해 다음을 릴리스 게이트로 추가했다.

- 300개 시드에서 1,000표 이상 생성해 자기투표와 비활성 대상이 한 번도 나오지 않는지 검사
- 작성 장면 260개 이상, 개인 이벤트 40개 이상, 핵심 관계 8쌍과 3인 대화 수량 검사
- CALIBRATION부터 LAST LIGHT까지 연속 실행해 각성 순서와 옛 플롯 누출을 검사
- GitHub의 Windows 가상 PC에서 Godot 4.7.2로 프로젝트 import, 모델 테스트, UI smoke, 메인 장면 부팅을 실제 실행
- Windows 배포 ZIP을 만들기 전에도 story consistency와 content audit을 다시 실행

---

# ASTRA 0.4.2

## 첫 각성부터 시작하는 항해

외부 관찰자의 사건 재구성 대신 ASTRA의 탐사요원으로 의료실에서 깨어난다. 첫 각성은 미라·준·다렌·노아 네 사람을 만나 배를 살피는 장면이다. 질문 시험, 승패 점수, 첫 격리 회의를 제거했다. 이후 여섯 장의 구조는 보존하며 새로운 기록 발견과 각성을 연결했다.

목적지 기억과 과거 관계가 회차마다 달라진다. 이전 회차의 기억 차이는 노트에 남고, 신뢰와 감정 잔향은 사건의 의심·스트레스와 별개로 이어진다. 중반에는 19년 전 도착 완료 기록이 나오지만 마지막 원인은 확정하지 않는다.

## 인물과 대화

새 인물 여덟 명의 이름·직업·말투·대사·개인 사정을 교체했다. 제공된 이미지로 전신 8종, 상반신 8종, 얼굴 8종, 감정 96종을 구성했다. 표정 시트는 셀 단위로 자르고 가장자리에 연결된 흰 배경을 제거했다. 원본은 수정하지 않았다.

탐색용 완성 장면 170개와 추리용 대사·변형을 연결했다. 장면에는 행동, 침묵, 두 사람의 대화, 0~4개 선택, 먼저 말 걸기, 지연 반응이 있다. 최근 장면을 피하고, 친밀·갈등·발견·루프·상실 조건으로 노출을 제한한다. 개인사·비밀·잔향 장면은 초반 행동 후 열리며 같은 장 안에서 중복하지 않는다. 같은 행동이라도 인물과 개인 정보의 맥락에 따라 관계 변화가 다르다.

## 플레이와 UI

탐색 장소별 사물과 조사 지점을 제공한다. 동료에게 바로 이동하고, 동행·기록 공유·숨기기·대기 등의 행동을 고른다. 휴대 기록기는 실제 야간 백업 효과로 이어진다. 주요 발견은 조사, 동료와의 확인, 놓쳤을 때 기록 전달로 얻을 수 있다.

현재 목표를 위에 두고, 상세 기록은 열어 보는 방식이다. 회의는 현재 화자와 상대를 크게 보여 주며 이전 발언은 별도로 읽는다. 플레이어 2표와 동률 우선권, 투표 흔들림을 없앴다. AP와 분 단위 비용의 중복을 정리했다.

## 유지한 기능과 호환

발언 기록, 모순 대조, 무고한 거짓말, 수동 가설, 관계 판단, 야간 행동, 저장 슬롯, 접근성, 오프라인 실행, 선택형 AI를 유지했다. 메타 저장 v8, 진행 저장 v3이며 v1/v2 진행 저장도 읽는다. 호환 ID는 유지하고 화면과 이미지에서 새 인물로 해석한다. 실제 0.3.0 소스가 만든 저장 파일의 증거와 RNG를 유지하며 재개하는 테스트를 통과했다. 투표 결과에는 전원 동일한 1표 규칙이 적용된다.

기존 항해 완료 기록과 새 이야기 진행은 별도로 저장한다. 기존 플레이어의 새 시작도 첫 각성부터 안내한다.

## 0.4.1 패스 — 첫판/둘째판 재설계와 서사 통합

CALIBRATION을 한 장소(의료실)로 좁혔다. 미라·준·다렌·노아 네 사람은 전부 의료실에서 자동으로 합류하며, 승무원을 만나기 위해 다른 방으로 이동할 필요가 없다. 조사 지점도 전원 패널 하나만 열려 있다. 회의·투표·밤은 CALIBRATION 전체에서 등장하지 않는다.

캠페인 6개 장(DEAD_AIR~LAST_LIGHT)이 여전히 쓰고 있던 0.3.x/0.4.0 시절 살인사건 플롯(함장 Ives, 연구원 Orin, 의료 책임자 Sael, 정비사 Tess, 관측 책임자 Ren, 항해 기록관 Ari)을 제거했다. 대신 각 장의 조사 화면(방·조작 기록·임무)을 voyage 레이어가 실제로 보여주는 미스터리에 맞춰 다시 썼다 — 목적지 이중 기록(DEAD_AIR), 세나·준의 엇갈린 근무 기록과 안쪽에서 열린 문(GLASS_GARDEN), 겹쳐진 신호(ECHO_WARD), 19년 전 도착 완료 기록(SILENT_ORBIT), 정착용으로 분류된 생태 표본과 달라진 과거 관계(RED_SHIFT), 불안정한 전력 계통과 손상된 오래된 기록(LAST_LIGHT). `victim`/`victim_role` 필드는 `subject`/`subject_role`로 이름을 바꿨다.

루프가 끝날 때마다 같은 "같은 목소리 / 손목에는 반창고가 없다" 화면이 반복되던 것을, 장마다 다른 제목과 디테일로 바꿨다(`AstraVoyageContent.reset_framing`). 첫 조사 지점·처음 만나는 동료·완료 버튼에는 금색 테두리로 된 넛지가 한 번에 하나씩만 표시된다.

전 구간 회귀 검사를 위해 `tests/story_consistency_tests.gd`(첫판 회귀 + 7개 장 연속 플레이 서사 정합성)와 `tests/content_audit.gd`(캐릭터별 장면·태그·선택 다양성 리포트)를 추가했다. 아직 남은 문제는 `docs/QA_REPORT.md`의 "남은 문제"에 정리했다 — 특히 170개 장면의 캐릭터별 차별화, 관계망 확장, 감정 잔향 세분화는 이번 패스에서 손대지 못했다.

## 0.4.2 패스 — 관계·잔향 시스템 고도화와 초반 난이도 재조정

**과거 관계(pair_history)** 를 방향별 이진 랜덤(A→B와 B→A가 다르게 나올 수 있던 버그)에서 순서 독립적인 단일 표로 바꿨다. `AstraCrewCatalog.pair_key()`가 항상 같은 키를 반환하므로 두 사람은 이제 정확히 같은 과거를 공유한다. 과거 유형은 `first_mission`/`old_colleagues`/`shared_accident`/`saved_each_other`/`professional_conflict`/`past_failure`/`once_close`/`shared_secret`/`record_only_history`와 몇몇 pair 전용 유형(예: 미라·마렌의 `shared_patient_or_ecology_case`) 13종으로 늘었고, pair마다 어울리는 후보군만 뽑는다. 루프마다 전부 다시 굴리지 않고 챕터가 진행될수록(0→3개) 재추첨 예산이 늘어나, 준·세나의 과거 같은 핵심 관계는 플레이어가 실제로 기억할 시간을 번다.

**감정 잔향(echo)** 을 단일 스칼라에서 `familiarity`/`trust`/`protection`/`conflict`/`grief` 다섯 축과 `tags` 배열로 분리했다. 이제 bond가 나빠져도 protection이나 grief는 독립적으로 남을 수 있다. 기존 세이브의 스칼라 echo 값은 `familiarity`로 자동 이관되며(같은 저장 필드 이름을 재사용해 세이브 파일 스키마는 그대로다), 특정 축이 임계값을 넘으면 `trusted_record`/`shielded_player` 같은 태그가 붙는다.

**첫판·둘째판 구조**를 데이터로 옮겼다. `AstraVoyageContent.ROOM_PROFILE`이 CALIBRATION(의료실 1곳)·DEAD_AIR(의료실·통신실·기록보관실)·GLASS_GARDEN(의료실·보안허브·수목구역)의 방 목록을 정의하고, 그 방에 실제 집이 없는 승무원(예: DEAD_AIR의 준)은 `home_room()`을 통해 자동으로 그 장의 첫 방에 모인다. `voyage_can_finish()`는 "전원을 만나야" 하던 공통 규칙 대신 장마다 실제로 필요한 사람(DEAD_AIR는 노아, GLASS_GARDEN은 세나)만 확인한다. AP 예산도 챕터별 표(`AstraCaseCatalog.AP_PROFILE`)로 옮겨 DEAD_AIR는 조사 2·대화 1·회의 1, SILENT_ORBIT부터 기존 3/3/2로 돌아온다 — 즉 DEAD_AIR의 첫 회의는 길게 논쟁하는 자리가 아니라 짧게 한 번만 끼어드는 자리가 된다. (회의를 0으로 완전히 없애 봤더니 NPC들이 플레이어의 증거를 전혀 듣지 못해 투표가 갈라지고 사건이 사실상 풀리지 않는 회귀가 나와, 1로 조정했다 — `tests/run_tests.gd`의 봇 시뮬레이션이 이 문제를 잡아냈다.) `unlocks.gd`의 `ALWAYS`에서 `meeting`/`vote`를 빼서 CALIBRATION 완료 후 처음 해금되는 기능으로 옮겼다.

**선택 effect**를 7종(help/record/share/wait/observe/defend/hide)에서 `confront`/`withhold`/`keep_copy`/`promise` 4종을 더해 11종으로 넓히고, 8명 전원의 "trust" 장면 선택지를 캐릭터마다 다른 문구·다른 조합으로 다시 썼다(이전에는 8명이 완전히 동일한 4개 선택지 문구를 썼다).

**정리**: `case_catalog.gd`의 "archive reconstructs... identity models" 주석과 CALIBRATION 원본 로스터 오타(다렌 누락), `opening_view.gd`의 콜드 오픈 설명 주석("damaged recorder", "killed"), `story_content.gd`에 남아 있던 구버전 "동률 우선권" 문구, `docs/UI_REFERENCE_NOTES.md`의 "2표" 서술, `tests/bots.gd`의 "identity models" 주석을 모두 현재 규칙에 맞게 고쳤다.

**남은 문제**는 여전히 크다 — 170개 장면의 캐릭터별 재배분과 개인 이벤트 다단계화(현재 캐릭터당 1개)는 이번 패스도 다루지 못했다. `tests/content_audit.gd`가 이제 진짜 게이트로 승격되어 이 두 가지를 FAIL로 정확히 보고한다(고의로 `build_windows.ps1`에는 연결하지 않았다 — 알려진 미완료 항목으로 빌드를 막지 않기 위해서다).
