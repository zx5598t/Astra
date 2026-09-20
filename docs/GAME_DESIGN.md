# ASTRA 0.5.3 설계 — HEARTBEAT

## 핵심 판타지

ASTRA는 “AI NPC 8명이 랜덤 문장을 말하는 마피아 게임”이 아니라, 반복될 때마다 과거와 관계가 조금씩 달라지는 여덟 동료와 함께 기록·사람·현장의 모순을 읽는 SF 사회추리 미스터리다.

플레이어가 중요하게 느껴야 하는 것은 “이번 Null이 누구인가?”뿐 아니라 다음 질문들이다.

- 이번에는 이 사람들이 어떤 관계인가?
- 평소와 다른 행동에는 어떤 이유가 있는가?
- 누가 어떤 정보를 실제로 알고 있는가?
- 이전 loop와 같은 사람인데 왜 반응이 조금 다른가?
- 기록과 사람의 말이 둘 다 진실이라면 현실 자체가 왜 어긋나는가?

## Chapter와 spotlight

| 호환 챕터 ID | 중심 mystery | 주요 human spotlight |
|---|---|---|
| CALIBRATION | 잠금 해제 기록과 첫 반복 | 미라와 첫 인간적 연결 |
| DEAD_AIR | 서로 다른 목적지 원본 | 노아 / 다렌, 미라의 귀환 기억 |
| GLASS_GARDEN | 순찰·배치 기억 불일치 | 세나 + 준 |
| ECHO_WARD | 수면 중 소렌의 음성 | 소렌 |
| SILENT_ORBIT | 19년 전 도착 완료 기록 | 루칸 |
| RED_SHIFT | 출항보다 오래된 시료 | 마렌 |
| LAST_LIGHT | 서로 다른 사본 보존 | 전체 관계 + main mystery |

미라는 Emotional Anchor이지만 다른 chapter의 주인공 자리를 빼앗지 않는다. 메인 미스터리의 해답 담당자가 아니라 “이 상황 속 사람들이 어떻게 버티는가”를 가장 자주 보여 주는 인물이다.

## Stable personality → variable history → rare residue

각 캐릭터는 세 층으로 구성한다.

**STABLE**
- 성격
- 직업
- 말투
- baseline
- stress response
- lie style

**VARIABLE**
- pair history
- 현재 갈등
- trust/comfort/respect/tension/protectiveness
- 무고한 비밀
- 누가 누구를 믿는지
- social theme

**RARE**
- strong echo
- 특별 private event
- loop residue
- 강한 관계 변화

Hidden role은 personality를 교체하지 않는다. Null Mira도 의무관이고, Null Jun도 현장형 엔지니어다. 달라지는 것은 어떤 정보를 숨기고 어떤 판단을 유도하는지다.

## Living Crew 모델

`AstraLivingCrew`는 다음을 제공한다.

- 캐릭터 baseline / stress response / lie style
- content weights
- 관계 5축
- relationship tags
- player behavioral profile
- social theme
- loop hook
- deviation reason vocabulary
- 캐릭터별 information sharing tendency

중요 deviation에는 reason / source_event / possible_followup을 남긴다. 이유 없이 랜덤하게 이상한 대사를 출력하지 않는다.

## Mira Emotional Anchor

미라는 반복의 감정적 연결선이다.

강화하는 것:
- CARE / DAILY / MEDICAL / PLAYER / RELATIONSHIP / ECHO / CONFLICT 콘텐츠
- WARM / PROFESSIONAL / STRAINED 관계 tone
- player behavior callback
- promise / privacy / accusation / defense memory
- familiarity / trust / protection / conflict / grief echo
- 다른 동료와의 독립적인 의료·자원·윤리 갈등

강화하지 않는 것:
- 강제 romance
- 항상 플레이어 편
- plot armor
- Null 면역
- 무조건적인 신뢰
- 모든 main mystery 설명
- 한 loop의 화면 독점

0.5.3 authored speaker pool은 Mira 80개지만 중후반 일반 loop의 optional Mira scene은 최대 4개다.

## Authored content

현재 `AstraVoyageContent.all_scenes()`는 기존 scene + `AstraStorylets052` + `AstraStorylets053`를 합쳐 **473개**를 제공한다.

새 0.5.3 콘텐츠는 대부분 ECHO WARD 이후에 배치한다. CALIBRATION의 필수 대사량은 늘리지 않는다.

`AstraStoryletScheduler`의 역할:
1. get candidates
2. requirement/context filter
3. recent family penalty
4. unseen scene modest priority
5. character/social-theme weight
6. rare/uncommon pity
7. deterministic session RNG pick

RNG는 선택만 한다. 내용은 authored data다.

## Autonomous Crew

`AstraCrewActivityModel`은 27개의 작은 autonomous beat를 관리한다.

- CALIBRATION / DEAD AIR: 0
- GLASS GARDEN: 최대 1
- ECHO WARD 이후: 0~2

플레이어가 장소에 들어오면 목격할 수 있고, 놓치는 것이 정상이다. 메인 진행 조건에는 사용하지 않는다.

일부 overheard scene은 끼어들기 / 듣기 / 지나가기 선택을 제공한다. autonomous actor는 반드시 ACTIVE여야 한다.

## Dialogue memory와 callback

NPC별 rolling memory는 무한 transcript가 아니라 최근 중요한 event만 보관한다.

기억할 수 있는 것:
- player_action
- accusation / defense
- shared clue
- promise
- conflict
- help
- pair defense

플레이어 성격 메뉴는 없다. repeated actions를 통해 evidence_first / people_first / protective / skeptical / secretive / confrontational / patient를 추정한다.

같은 선택을 반복하면 관계 효과는 줄어들 수 있고, 캐릭터별 authored callback이 패턴을 언급할 수 있다.

## Knowledge invariant

`AstraKnowledgeModel`은 “누가 무엇을 왜 아는가”를 명시적으로 기록한다.

fact 상태:
- player found
- specific NPC knows
- public
- provenance path

전파:
- player → NPC
- NPC → NPC
- public → active participants

NPC A가 사실 F를 모르면 A→B 공유는 실패한다. A가 B에게 말해도 C에게 자동 확산되지 않는다.

Null도 이 invariant를 따른다. hidden role 때문에 모든 정보를 자동으로 알지 않는다.

## Evidence ownership

voyage fact는 플레이어가 발견하면 먼저 player-owned 정보로 기록한다. 선택에 따라 특정 NPC에게 공유된다.

Notebook에는 최근 정보에 대해 가볍게:
- 알고 있음: 나 / 노아
- 아직 비공개 / 공개됨

정도만 표시한다. 복잡한 권한 매트릭스는 만들지 않는다.

## DecisionTrace

`AstraDecisionModel`은 중요한 행동의 이유를 테스트 가능한 구조로 남긴다.

현재 연결:
- vote
- meeting suspect / defense / dispute / record reaction
- autonomous information share

DecisionTrace는 reasons / strongest_reason / natural-language explanation을 보존한다. 투표 UI는 숫자 점수 대신 이유 문장을 보여 준다.

첫 격리 투표는 noise를 제거하고 근거가 약하면 기권을 늘린다. 두 번째 날부터 관계 영향이 점차 커진다.

## Innocent lie / misremembering

무고한 진술 차이는 다음 원인을 가질 수 있다.

- EMBARRASSMENT
- PROTECT_OTHER
- HIDE_MISTAKE
- KEEP_PROMISE
- PERSONAL_SECRET
- FEAR
- MISREMEMBERED

MISREMEMBERED는 `lie=false`다. 해당 캐릭터는 실제로 잘못 기억하고 있기 때문에 lie detection 대상이 아니다.

## Meeting

Meeting Thread:
- FACT_THREAD
- RELATION_THREAD
- DECISION_THREAD

새 0.5.3 multi-line pair/trio scene도 각 줄에 anchor / reply / clarify / challenge / support / proposal / agreement / inference 등 관계 metadata를 둘 수 있다.

회의는 앞 사람의 말을 실제로 받는 것이 우선이며, 한 사람이 말한 뒤 모두가 자기 독백을 한 줄씩 하는 구조를 피한다.

## Curiosity Questions

Notebook의 질문은 OPEN / PARTIAL / ANSWERED / CHANGED 상태를 사용한다.

최대 3개만 전면에 표시한다. 질문이 ANSWERED된 뒤 다음 loop의 기록이 전제를 뒤집으면 CHANGED로 다시 열 수 있다.

Notebook은 추론 보조이며 자동 정답 판정은 하지 않는다.

## Save compatibility

기존 진행 저장과 내부 캐릭터 ID는 유지한다. 0.5.3의 새 상태는 기존 `voyage` / memory dictionary 안의 선택적 key로 추가했다.

예:
- storylet_pity
- memory_tags
- promise_history
- autonomous_recent
- visible_signatures
- evidence_ownership

오래된 저장에 해당 key가 없으면 기본값을 사용한다. 이전 저장을 자동 삭제하거나 강제 재시작하지 않는다.

## 접근성과 진행

기존 원칙 유지:
- reduce motion
- 큰 글씨
- 회의 발언 자동 넘김 속도
- 금색 CTA
- 점진 해금
- 초반 단순화

설정의 auto advance는 “회의 발언 자동 넘김”이며 탐색 선택·투표·밤 행동을 자동 처리하지 않는다.

## 품질 기준

릴리스 전에 최소 다음 질문에 YES여야 한다.

- NPC는 방금 앞 사람이 한 말에 반응하는가?
- NPC는 실제로 아는 정보만 사용하는가?
- non-abstain vote에는 이해 가능한 이유가 있는가?
- 중요한 deviation에는 원인이 있는가?
- 같은 seed + 같은 행동은 재현 가능한가?
- 다른 loop의 차이가 플레이어 눈에도 보이는가?
- Mira는 기억에 남지만 다른 캐릭터 spotlight를 덮지 않는가?
- Mira는 독립적인 판단과 관계를 갖는가?
- CALIBRATION / DEAD AIR가 다시 텍스트 과부하가 되지 않았는가?
