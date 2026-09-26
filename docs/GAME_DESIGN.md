# ASTRA 설계 — 1.1.0 LIVING PATHS (현재 기준)

> 1.0.1의 직접 Link 추리·회의·투표·공정성 계약을 그대로 두고, 1.1.0은 **선택 이후의 장면·정보 순서·출처·사람 반응·다회차**를 개선한다. Canon/Null/사건 정답을 분기시키지 않는다.

## 1.1.0 핵심 — "무엇을 알았나 + 그 진실을 누구와 어떻게 다뤘나"

- **reconverging branch.** 공통 진실 → 중요한 선택 → 1~2 Stage의 다른 정보/사람/대사 → 다시 공통 canon으로 합류. 별도 BranchManager/route graph 없음.
- **다섯 anchor.** DEAD_AIR, ECHO_WARD, RED_SHIFT, BORROWED_DAYS, THREE_MINUTES_DARK. 기본은 2개 선택, 세 전략이 실제로 다른 THREE_MINUTES_DARK만 3개.
- **선택의 비용은 콘텐츠.** 공개 시점, 누구와 먼저 확인했는지, 직접 본 것과 전언의 차이, 후속 개인 scene과 meeting context가 바뀐다. karma/affinity/branch currency 없음.
- **KnowledgeModel까지 바뀐다.** PUBLIC은 실제 public fact, verify-first는 특정 사람과의 share, THREE_MINUTES_DARK는 선택 구역만 DIRECT provenance.
- **기존 ConsequenceModel 사용.** IMMEDIATE / DELAYED / NEXT_DAY / NEXT_LOOP. event id dedup, save/load, rewind, next reconstruction residue를 새 시스템 없이 처리.
- **선별 micro-arc.** consequence가 실제 있는 8개 authored choice scene만 1.0 loop에 제한적으로 복귀. scheduler의 breathing room/노출 철학 유지.
- **Replay.** 같은 seed/Null/base packet에서도 선택한 route에 따라 visible scene, provenance, meeting opener, next-Stage callback이 달라진다.
- **Finale.** share/wake/keep action은 플레이어가 고른 그대로. visible campaign history가 reception과 callback texture만 바꾼다.
- **Save.** Meta v12 / Snapshot v4. route choices/provenance/history는 기존 nested voyage/stage state의 optional field.

## 대사 원칙
NPC는 먼저 질문에 대답하고, 그다음 자기 방식으로 해석한다. 인물별 추리 방법: 미라=사람 상태/의료 한계, 준=장비/작업 순서,
다렌=조건/전제, 노아=원문/출처, 세나=출입/문/동선, 소렌=원음/간격/전언 과정, 루칸=위치/거리/경로, 마렌=생장/환경/생활 흔적.
Link/final/stance line은 이 차이를 우선하며, 단순 말투 치환으로 캐릭터를 구분하지 않는다.

## Deep / rewind / replay
Deep에는 campaign branch anchor가 나오지 않는다. Dawn rewind는 그 아침 이전 route history는 유지하고 이후 선택은 되돌린다.
NEXT_LOOP callback은 “지난번에 네가…” 같은 직접 기억이 아니라 익숙한 확인 순서·경계심 같은 residue로만 표현한다.

---

# ASTRA 설계 — 1.0.0 CONVICTION (현재 기준)

> 1.0.0 절이 현재 규칙이다. 0.8.0 절의 뼈대(Stage/Day, Day Packet, 지식 모델, 판단 모델)는 그대로이며, 1.0.0이 바꾼 곳만 여기 적는다.

## 1.0.0 핵심 — "내가 연결하고, 방이 움직인다"

- **방은 말해진 문제만 따진다.** 회의 보드의 두 알리바이가 동시에 맞을 수 없어도, 누군가 그걸 소리 내어 짚기 전까지 NPC 판단에 들어가지 않는다(자기 쪽을 아는 당사자는 예외). 짚는 사람: 탐사요원(연결·대질·확인 질문), 또는 꼼꼼한 승무원이 가끔 스스로(`_thread_claims`, 노아·다렌·루칸이 잘 알아챔). 한쪽이 공개적으로 사정을 설명하면 그 충돌은 더 이상 세지 않는다.
- **묻지 않은 기록은 서랍 속에.** 탐사요원이 대화에서 들은 기록·목격은 담당자가 회의에서 0.9 이상 확률로 꺼낸다. 묻지 않은 것은 성향 × 0.13 정도(`UNASKED_SHARE`).
- **혼자 본 것은 투표까지만.** 자기만 가진 목격·기록 하나로는 공개 지목을 하지 않는다(투표는 한다). 탐사요원이 이미 들었거나 두 번째 출처가 같은 쪽을 가리키면 공개적으로 말한다(`_lone_private_conviction`).
- **증거 곡선 완화.** 흔적 하나가 한 사람을 바로 가리키는 비율을 줄였다(Day 1 5%, Day 2 20%, Day 3 55%). 서로 다른 사람이 가진 두 흔적이 만나는 곳이 답이다.
- **Null은 한 사람을 민다.** 하루에 희생양 한 명을 정해(자기의 거짓 목격 대상, 또는 공개적으로 이미 문제가 있는 사람) 지목과 표를 모은다. 공개된 사실만 쓴다(`null_scapegoat`).

## 연결 (진술 ↔ 근거)

회의 발언 중 하나. 들은 **진술 하나**(누군가의 알리바이, 공개된 목격, 공개된 해명)를 고르고, 아는 **근거 하나**(기록·목격·전언·전문 소견·다른 사람의 진술·같은 사람의 이전 진술) 또는 서로 다른 사람의 근거 둘을 고른다. 판정은 내용(장소·사람·시각·해명 방식)으로만 한다 — 역할은 절대 읽지 않는다. 그래서 같은 것을 보여 주는 근거는 모두 통한다.

| 결과 | 뜻 | 방의 반응 |
|---|---|---|
| 모순 | 둘은 동시에 맞을 수 없다 | 근거 공개, 당사자 대답(Null은 성향대로 반박·양보·화제 돌리기·신뢰 공격·침묵, 무고한 사람은 사정 설명 또는 버팀), 판단 변화 |
| 좁힘 | 근거가 몇 사람 중 하나를 가리킨다 | 근거 공개, 후보 정리 |
| 뒷받침 | 근거가 그 말과 같은 곳을 가리킨다 | 변호로 작동 |
| 전언뿐 · 같은 출처 · 이미 설명됨 · 불분명 | 판단할 수 없는 이유를 말해 준다 | 벌점 없음 |
| 관계없음 | 두 가지가 서로를 가리키지 않는다 | 방의 신뢰가 조금 줄고, 지목된 사람이 방어적으로 |

두 개의 무리 기록이 한 사람에게서만 겹치면 모순으로 인정한다(교집합).

## 회의 흐름

- 하루 **발언 3번**(EMPATH +1): 연결, 기록 꺼내기, 되묻게 하기, 감싸기, 지목 등. **확인 질문 3번**(별도): 지금 논점에 맞게 — 기록 출처, 무엇을 봤는지(얼굴/태그), 시각 대조, 동행자에게 직접 확인, 전언의 출처, 사건과 관계있는 사정인지.
- 보드는 사람마다 지금 상태를 말로 보여 준다: 아직 확인 전 · 목격의 후보 N명 중 · 기록이 가리킴 · 진술이 부딪힘 · 사정이 설명됨 · 기록이 뒷받침 · 다시 물어도 같음. 숫자는 없다.
- 회의 끝 정리: 부딪힌 말 · 설명된 것 · 아직 열린 것 · 방이 갈리는/기우는 곳.
- 마지막 말은 오늘 실제로 걸린 것에 답한다(맞지 않은 연결, 공개된 사정, 탐사요원의 지목).
- 투표: 사람을 고른 뒤 **이유 하나**(아는 근거 중에서, 또는 "직감")를 고른다. Day와 함께 남고 결과 화면에 다시 나온다. 채점하지 않는다.

## 패배와 되감기

- Stage에서 지면(탐사요원 사망 또는 Null 우세) **그날 아침으로 한 번** 되감을 수 있다. 같은 재구성, 같은 진실. 기억하는 건 탐사요원뿐 — 들었던 말은 메모와 "지난번에 들은 말" 표시로 남고, 승무원은 아무것도 모른다(지식 모델에 아무것도 추가하지 않는다).
- 되감기를 쓰면 "처음부터 새로 재구성"(새 seed)과 "이전 STAGE로 돌아가기"가 남는다. DEEP RECONSTRUCTION에는 되감기가 없다(한 목숨).

## 탐사요원 관계의 시작

첫 만남 교환에 붙은 tone(예: 세린×소렌 intellectual_resonance, 시아×세나 protective_friction)은 Stage 상태에 남고, 신뢰를 아주 조금(±0.02) 움직이며, 다음 날 그 사람의 첫마디가 그 교환으로 돌아온다. 진실·Null·단서는 같다(테스트).

## 인터루드 작업 네 계열

신호 분석(간섭 채널 → 두 채널 정렬 → 도착 시각으로 방향) · 회로 진단(측정 3회 → 고장 모듈 → 용량 맞는 우회선) · 기록 타임라인(순서 → 맞지 않는 경계 → 뜻) · 귀환 경로(산소 예산 안의 왕복, 봉쇄 통로, 선택 스캔). 시드별 배치, 키보드/마우스, 리셋(R), 나중에(Esc = 부분 성공), 시간 제한 없음.

---

# ASTRA 설계 — 0.8.0 CONTAINMENT (1.0.0의 바탕)

> 아래 0.8.0 절이 현재 규칙이다. 그 아래의 0.7.x 설계는 인물·관계·스토리 canon의 배경 자료로 남겨 두며,
> 탐색(EXPLORE)·조사(INVESTIGATION)·기권 투표 같은 0.7.x 진행 규칙은 더 이상 쓰지 않는다.

## 0.8.0 핵심

“시스템이 많은 게임”이 아니라 **사람을 의심하게 만드는 게임**. 플레이어는 메뉴가 아니라 사람과 싸운다.

- **Stage = 한 판**, Day = 그 안의 라운드. PART I(1~4) Null 1, PART II(5~) Null 2 + 프로토콜.
- **Day = 아침 → 대화 → 회의 → 투표 → 밤.** 매일 정확히 한 명 격리, 기권 없음, 동률은 결선, 결선 동률은 탐사요원이 결정.
- **패배**: Null 표 ≥ (살아 있는 Null 아닌 승무원 + 탐사요원), 또는 탐사요원 사망. 타임아웃 없음.
- **정체 비공개**: 격리 시점에는 역할을 보여 주지 않는다. Stage 결과에서만 공개.

## Day Packet (Stage 진실과 하루 정보의 분리)

`AstraCaseGenerator.generate_day_packet(case, seed, day, active, nulls)`가 하루치 사건과 정보를 만든다.
- 사건 1개, 위치/진술, 조각(fragment) 3~7개: 직접 목격 · 시스템 기록 · 전문가 추론 · 전언 · Null의 거짓 목격 · 알리바이 기록 · 무고한 거짓말 노출 · 공모 노출.
- **공정성 계약**(`validate_day_packet`): 행동한 Null을 가리키는 증거는 무고한 사람이 두 경로 이상 가진다(두 소유자 또는 소유자+백업). 두 흔적이 남기는 사람 수는 날마다 **증거 곡선**(`NARROW_CURVE`)에서 뽑는다: Day 1은 보통 2~3명, Day 2는 1~2명, Day 3 이후는 대부분 1명. 같은 행위자는 매일의 집합에 모두 들어 있으므로 어제를 기억하면 오늘이 더 좁혀진다. 이름을 바로 대는 목격·기록은 예외다(방이 작아도 목격 특징과 기록 종류를 함께 골라 목표에 가장 가깝게 맞추고, 그래도 안 되면 두 번째 목격자가 기록을 대신한다). 거짓 목격은 항상 반박 가능하다.
- **Stage 주제**: 1 한 가지 모순 · 2 서로를 감싸는 거짓말 · 3 전해 들은 말의 왜곡 · 4 시간/위치를 흔드는 거짓 목격 · PART II 혼합.

## 정보는 사람에게 있다

- `AstraKnowledgeModel`: 조각은 가진 사람만 안다. 회의에서 말한 것만 공개된다. 밤에 함께 있던 사람끼리 들은 말이 퍼진다.
- **기록은 열어야 안다**: SYSTEM_RECORD/ALIBI_SUPPORT는 담당자가 습관대로 이미 봤거나, 탐사요원이 “같이 열어 본다”를 골라야 안다. 아무도 열지 않은 기록 중 Null을 가리키는 것은 밤사이 지워질 수 있다(시간 제한이 아니라 방치의 대가).
- **한 사람의 말은 약하다**: 다른 사람의 목격은 독립된 두 번째 출처가 같은 쪽을 가리킬 때까지 절반의 무게. 반박되지 않은 변명은 기록의 무게를 줄인다.

## 판단 (AstraDecisionModel)

- 증거 범주별 가중치(인물별) + 인물별 **확신 기준(conviction)**. 확신이 없으면 믿는 사람의 공개 지목(bandwagon, 관계), 탐사요원의 입장(regard × 신뢰)을 따른다.
- 인물의 약점이 실제로 나타난다: 미라(미룸), 준(서두름·친한 사람에 휩쓸림), 다렌(감정 과소평가), 노아(기록 과신), 세나(위험 과잉 대응), 소렌(너무 늦게 말함), 루칸(물리적 정합성 우선), 마렌(익숙한 사람의 변화를 늦게 받아들임).
- **Null 생존 방식**(비공개): DEFLECTOR / QUIET / ALLY / COUNTERATTACK. 말투는 바뀌지 않는다. 두 Null은 항상 한 팀처럼 움직이지 않는다.
- 모든 판단은 DecisionTrace로 남고, 화면에는 인물 말투의 한 문장으로만 나온다(“확률로만 보면 준. 인증 로그가 가리키는 방향. 확정은 아니야.”).

## 대화

- 얼굴 한 번 클릭 = 대화 시작(대화 1회 소모, 하루 2~3회). 첫 진술 뒤 추가 질문 2개.
- 선택지는 최대 3개, 아는 것에서만 만들어진다: 어긋난 진술/기록/목격 들이밀기(차분히 / 몰아붙이기), 기록 같이 열기, 누구를 봤는지, 어제 한 말, 누가 걸리는지, 안심시키기.
- 반응: 설명, 변명, 부분 인정, 역공, 숨긴 사정 고백, 회피, 착각 인정. 같은 사실도 태도에 따라 신뢰·긴장·이후 반응이 달라진다.
- 어제 지목/변호한 사람은 오늘 그것을 기억하고 먼저 말한다. 작은 습관은 Stage당 한 번 정도만.

## 회의

- 모두의 위치가 보드에 오른 뒤, 논점이 하나씩: 기록 공개 → 당사자 답변(변명) → 전문가 반박 → Null의 두 번째 변명(“예전 펌웨어면…”) → 멈춤.
- 논점 종류: 기록, 목격, 거짓 목격(프레임), 무고한 거짓말 지적, 말 바꿈 되짚기, 어제 판단 돌아보기, 지목.
- 탐사요원 개입 1회(엠패스 2회): 그 논점에 맞는 2~3개(재확인·되묻기·감싸기·기록 꺼내기·근거 묻기·지목). 근거 없는 지목은 힘을 잃고 지목한 사람이 눈에 띈다.
- 분위기: 첫날 조심스러움 / 말이 날카로워짐 / 돌려 말하지 않음 / 사망 직후 침묵.

## 투표와 밤

- 투표 전 가장 많이 지목될 두 사람의 마지막 한마디(숨긴 게 있는 무고한 사람: “숨긴 건 있어. 네가 찾는 이유와는 달라.”).
- 표 공개는 한 사람씩, 인물 말투로. 격리 뒤 당사자 한마디 + 가까운 사람의 반응 + 포드가 닫힘.
- 밤: Null이 공개된 행동을 근거로 위협을 판단해 한 명을 노린다(탐사요원 포함). 가디언 Aegis는 Stage당 2회, 같은 문 연속 불가, 자기 자신 가능, 막아 내면 누가 노려졌는지만 알 수 있다.

## 공식이 되지 않게 (0.8.0 최종 패스)

- 무고한 사람도 Null과 같은 모양의 흔적을 남긴다: 창피한 거짓말(동행을 부정당함), **정직한 착각 목격**(생김새가 비슷한 사람을 잘못 봄),
  Null의 **빌린 알리바이**(혼자 있던 사람과 같이 있었다고 주장). 누구든(Null 포함) **무해한 관찰**(`ROUTINE`)을 가질 수 있다.
- Null은 그날 첫 지목을 서두르지 않는다(공개된 근거나 자신을 향한 압박이 있을 때만). 밤 표적은 위협 순위 + Null 성향 + 차폐막 예측(같은 문 이틀 연속 불가) + 관계.
- 측정: `tests/probe_replay_080.gd`(분포와 공식), `tests/probe_agency_080.gd`(플레이어 없이 누가 맞히는가), `tests/probe_packets_080.gd`(증거 곡선).

## 전해 들은 말과 출처

- 전해 들은 사람이 회의에서 말한다(왜곡됐을 수 있음). 원래 본 사람이 스스로 정정하는 일은 드물고, 탐사요원이 “본 사람에게 직접 묻기”로 개입할 수 있다.
- 근거는 출처대로 말한다: 내가 본 것 / 내가 확인한 기록 / 누가 봤다는 것 / 누가 전한 말 / 누가 설명한 장비 구조.

## 인터루드 · 탐사요원 · Deep

- 인터루드 9개(Stage 2·3·4·6·8·10·11·12·13): 작은 방, 2~3명, 1~3분, 과제는 최대 하나(신호 맞추기 · 전력 경로 · 순서 맞추기 · 한 곳 선택). 실패·건너뛰기는 막힘이 아니다.
- 탐사요원 등록: 이름과 외형(임시 6종). 승무원은 계속 “탐사요원”이라 부른다. 도트는 공간, 초상화는 감정.
- 감정 잔향(Residual Echo)과 죽음의 잔향: 다음 첫 아침에 최대 한 줄. 역할·정답은 남기지 않는다.
- 최종 악장: 마지막 선택 → 에필로그(신뢰/균열/발견) → 캠페인 콜백 → ASTRA 마지막 메시지 → 크레딧 → 심층 재구성 해금.
- 심층 재구성: 한 목숨, 깊이마다 런 시드로 생성, 4부터 조건 하나(잡음·정전·분열·메아리·고요한 갑판), 7부터 Null 둘. 스탯 강화 없음.

## 화면

- 상단 한 줄(PART·STAGE·DAY, 4단계, 깨어 있는 사람), 지금 할 일 한 줄, 그리고 각 단계 화면. 다음 단계 버튼은 각 화면 안에 하나뿐.
- 아침·결과는 큰 초상화의 장면(AstraVNStage). 한 번 클릭에 1~3문장.
- 노트는 도움일 뿐 필수 HUD가 아니다. 용어 풀이는 H.

## 스토리 연속성

`docs/STORY_LEDGER_080.md` 참고: Stage = ASTRA의 한 번의 깨어 있는 주기, 재동기화 뒤 모두가 다시 깨어나고 탐사요원만 기억한다, Null은 매 주기 새로 깨어난다.

---

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
