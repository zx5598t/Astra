# ASTRA 설계 (0.7.0 SECOND WATCH 기준 갱신, 원문은 0.5.7 CLEAR SIGNAL)

## 핵심 판타지

ASTRA는 “AI NPC 8명이 랜덤 문장을 말하는 마피아 게임”이 아니라, 반복될 때마다 과거와 관계가 조금씩 달라지는 여덟 동료와 함께 기록·사람·현장의 모순을 읽는 SF 사회추리 미스터리다.

플레이어가 중요하게 느껴야 하는 것은 “이번 Null이 누구인가?”뿐 아니라 다음 질문들이다.

- 이번에는 이 사람들이 어떤 관계인가?
- 평소와 다른 행동에는 어떤 이유가 있는가?
- 누가 어떤 정보를 실제로 알고 있는가?
- 이전 loop와 같은 사람인데 왜 반응이 조금 다른가?
- 기록과 사람의 말이 둘 다 진실이라면 현실 자체가 왜 어긋나는가?

## Chapter와 spotlight

0.7.0부터 캠페인은 ACT I(Day 1~7)과 ACT II(Day 8~13) 두 막으로 나뉜다. ACT는 저장되는 값이 아니라 campaign day에서 파생된다(`AstraVoyageContent.act_for`). ACT III는 이 버전에서 만들지 않는다.

| 호환 챕터 ID | Day | 중심 mystery | 주요 human spotlight |
|---|---|---|---|
| CALIBRATION | 1 | 잠금 해제 기록과 첫 반복 | 미라와 첫 인간적 연결 |
| DEAD_AIR | 2 | 서로 다른 목적지 원본 | 노아 / 다렌, 미라의 귀환 기억 |
| GLASS_GARDEN | 3 | 순찰·배치 기억 불일치 | 세나 + 준 |
| ECHO_WARD | 4 | 수면 중 소렌의 음성 | 소렌 |
| SILENT_ORBIT | 5 | 19년 전 도착 완료 기록 | 루칸 |
| RED_SHIFT | 6 | 출항보다 오래된 시료 | 마렌 |
| LAST_LIGHT | 7 | 서로 다른 사본 보존 — ACT I 결말 | 전체 관계 + main mystery |
| SECOND_WATCH | 8 | 도착 이후 근무 일지 — ACT II 시작 | 노아 + 세나 |
| BORROWED_DAYS | 9 | 몸에 남은 습관과 어긋난 관계 기록 | 세나 + 준 |
| BLIND_DECK | 10 | 지도에서 지워진 정비 구역 | 루칸 + 노아 |
| THREE_MINUTES_DARK | 11 | 동시다발 문제, 직접 목격 vs 전언 | 루칸 + 노아 |
| CONTINUITY | 12 | 재난이 아니라 평범한 일상 기록 | 미라 + 마렌 |
| THRESHOLD | 13 | 도착→생활→재수면 — ACT II 결말 | 노아 + 다렌 |

미라는 Emotional Anchor이지만 다른 chapter의 주인공 자리를 빼앗지 않는다. 메인 미스터리의 해답 담당자가 아니라 “이 상황 속 사람들이 어떻게 버티는가”를 가장 자주 보여 주는 인물이다. ACT II에서도 미라가 optional content를 독점하지 않도록 CONTINUITY의 스포트라이트를 마렌과 나눴다.

### ACT II 게임 디자인 원칙

ACT II는 “ACT I보다 단서가 어려운 버전”이 아니다. 새 stat system이나 새 manager 없이, 기존 시스템이 이미 지원하는 능력을 다르게 조합해서 체감을 바꾼다.

- THREE_MINUTES_DARK: 엔진은 `active_incident`를 한 번에 하나만 지원한다. “동시다발”은 서사적으로 세 곳에서 동시에 문제가 발생했다고 서술하고, 기계적으로는 플레이어가 하나만 직접 처리하며 나머지는 기존 NPC 자율 판단(DecisionTrace/PersonalMotive/relationship 가중치) 시스템이 처리한다. 새 hidden-Null 지름길이 아니다.
- BLIND_DECK: 동행에 따라 2차 관찰(미라=의료 흔적, 준=배선, 다렌=시스템 구성, 세나=출입 흔적, 소렌=통신/잡음, 마렌=생태 흔적)이 달라지지만, core fact는 어떤 동행이든 기존 investigation point로 도달 가능하다.
- storylets_052~055.gd의 MID_CHAPTERS/LATE 게이트와 incident_model.gd의 모든 incident에 ACT II 6일을 추가했다. 기존 608개 personality/relationship 라이브러리와 8종 incident가 새로 만들지 않아도 ACT II에서 계속 등장한다.

## CLEAR SIGNAL: player-visible narrative focus

0.5.7은 새 authoritative system을 추가하지 않고 storylet selection의 **노출 밀도**를 조절한다. 목표는 한 loop에 중요한 이야기를 더 많이 보여 주는 것이 아니라, 플레이어가 이미 본 2~3개의 핵심 스레드를 기억하고 이어갈 수 있게 하는 것이다.

focus context는 loop_focus_families / loop_focus_events / recent visible focus / speaker_exposure / explicit_topic처럼 플레이어가 실제로 알 수 있는 값만 사용한다. hidden truth, Null assignment, motive assignment, raw relationship float는 입력하지 않는다.

- genuinely new FOCUS family만 soft thread budget을 소비한다.
- mandatory/progression과 authored FOLLOWUP/consequence는 별도 새 스레드로 세지 않는다.
- 같은 visible chain의 continuation은 recent-family 억제를 우회하고 soft weight 우대를 받는다.
- explicit topic과 direct pinned-question match는 계속 seekable하다.
- 두 개의 active high-salience thread 뒤에 열리는 unrelated thread는 점진적으로 확률을 낮추되 hard cap으로 금지하지 않는다.
- 같은 화자의 optional scene이 몰리면 speaker exposure가 soft penalty를 준다.
- dense loop의 두 번째 autonomous beat는 삭제하지 않고 defer한다.

이 변경은 save schema를 늘리지 않는다. 기존 voyage nested state를 hydrate하며 v10 호환성을 유지한다. CALIBRATION과 DEAD AIR의 학습 구조나 필수 텍스트량도 늘리지 않는다.

500-loop release gate는 평균/P95뿐 아니라 4+ unrelated thread 빈도, continuation 발생, zero-meaningful 연속, visible signature variety, autonomous coverage, 0.5.3 authored coverage, rare repeat, Mira max exposure를 함께 검사한다.

## ECHOES: 보이는 결과와 실제 경험의 장기 기억

0.5.6은 authoritative social model을 바꾸지 않는다. UI는 기존 KnowledgeModel / DecisionTrace / relationship / consequence state를 읽고, 플레이어가 실제로 알 수 있는 부분만 qualitative feedback으로 변환한다.

- raw relationship 수치, magnitude, internal source id, motive enum, hidden role, Null list/probability는 player-facing summary에서 제외한다.
- 같은 pair/day/axis 변화는 aggregate하고 작은 변화는 숨긴다.
- night feedback은 즉시 consequence, briefing은 relationship/opinion aftermath로 역할을 분리한다.
- Notebook은 current-voyage working memory다.
- Crew Archive / Observation Codex는 cross-voyage authored observation이며 실제 경험 근거가 있어야 unlock된다.
- STABLE/OBSERVED/ECHO 32개는 정답 canon이 아니라 플레이어가 목격한 성격·상황·잔향 기록이다.
- CALIBRATION은 Codex 시스템 설명이나 연속 toast를 추가하지 않는다.

save v10의 codex_entries_unlocked와 snapshot의 codex_known/codex_unlocks_pending을 재사용한다. resume에서는 meta에 이미 영구 저장된 pending만 제거해 동일 unlock을 새 기록으로 재보고하지 않으며, 현재 run에서 처음 얻은 다른 observation은 정상적으로 이어진다.

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

## FAULT LINES: 이유를 추리하는 층

0.5.5의 Personal Motive는 Hidden Role의 보조 이름이 아니다. motive assignment는 Null과 독립이고 일부 NPC에게만 주어진다. 플레이어는 “거짓말했다 → Null”이 아니라 “거짓말한 이유가 무엇인가 → 그 이유가 사건과 연결되는가” 순서로 판단한다.

`AstraPersonalMotiveModel`은 compatible motive, 1~3명 deterministic assignment, multi-source progress, DEV truth report를 담당한다. 플레이어 UI는 motive enum/상태명을 직접 보여 주지 않고 관찰 문장만 남긴다.

`AstraIncidentModel`은 chapter eligibility, deterministic selection, 선택/결과를 담당한다. 한 loop의 visible incident는 최대 1개이며 Consequence/Knowledge의 기존 구조와 함께 사용한다.

`AstraForeknowledgeModel`은 실제 과거 incident history가 있을 때만 foreknowledge를 허용하고, 정보 source label, 안전한 반복 scene compression, momentum drought state를 담당한다.

Cooperative Investigation은 기존 companion을 재사용한다. core fact는 보존하고 secondary observation만 달라져 특정 동행자를 고르지 않았다는 이유로 canon이 막히지 않는다. Delegation도 optional investigation에만 적용한다.

신규 save state는 기존 `voyage` 안의 optional nested field로 들어간다: motives / incident_history / active_incident / foreknowledge_used / scene_seen_counts / momentum_state / delegation_history. 0.5.4 저장에 필드가 없어도 기본값으로 hydrate한다.

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

0.5.4 authored speaker pool은 Mira 88개지만 중후반 일반 loop의 optional Mira scene은 최대 4개다.

## Authored content

현재 AstraVoyageContent.all_scenes()는 기존 scene + AstraStorylets052 + AstraStorylets053 + AstraStorylets054 + AstraStorylets055를 합쳐 **608개**를 제공한다. 0.5.5 신규 authored/reactive scene은 71개다.

0.5.4 Routine/Micro-Arc/Consequence 콘텐츠도 대부분 ECHO WARD 이후에 배치한다. CALIBRATION의 필수 대사량은 늘리지 않는다.

`AstraStoryletScheduler`의 역할:
1. get candidates
2. requirement/context filter
3. recent family penalty
4. unseen scene modest priority
5. character/social-theme weight
6. rare/uncommon pity
7. deterministic session RNG pick

RNG는 선택만 한다. 내용은 authored data다.

## Crew Routine — spatial baseline

Routine은 생활 시뮬레이션 시간표가 아니라 **공간적 baseline**이다. 8명 합계 36개의 정상 활동을 가지고, authored deviation 27개는 10개의 명시적 reason 중 하나를 사용한다. 중요한 deviation에 random_room 같은 이유는 허용하지 않는다.

플레이어는 반복을 통해 “이 사람은 보통 어디에서 무엇을 하는가”를 배운다. 그 baseline이 있기 때문에 다른 방에 있거나 평소와 다른 활동을 할 때 질문이 생긴다. routine deviation은 행동 단서일 뿐 Null의 hard evidence가 아니다.

## Consequence & Micro-Arc

AstraConsequenceModel은 IMMEDIATE / DELAYED / NEXT_DAY / NEXT_LOOP 네 timing을 관리한다. authored event 23개는 queue 상한과 expiry를 가지며 NEXT_LOOP만 다음 voyage memory에 carry된다.

AstraStorylets054는 각 인물에 4-beat 대표 micro-arc를 하나씩 둔다. arc는 quest 목록으로 노출하지 않고 storylet scheduler의 조건/pity/recent suppression을 사용한다. consequence stage는 일반 selector에서 제외해 선택보다 먼저 결과가 나오는 것을 막는다.

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

기존 진행 저장과 내부 캐릭터 ID는 유지한다. 0.5.4의 새 상태도 기존 `voyage` / memory dictionary 안의 선택적 key로 추가했다.

예:
- storylet_pity
- memory_tags
- promise_history
- autonomous_recent
- visible_signatures
- evidence_ownership
- routine_state / routine_observations
- micro_arc_state / micro_arc_pity
- consequence_queue / consequence_carry
- pinned_question / opinion_changes

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
