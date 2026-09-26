# ASTRA 1.0.1 — CONVICTION RELEASE POLISH

1.0.0의 직접 추리 구조는 그대로 두고, 출시 직전 실제 플레이에서 걸리던 자동 해결·마우스 조작·스크롤·최소 창 크기·CI 문제를 정리한 안정화 업데이트입니다.

- **내가 조사한 것이 실제로 방을 바꿉니다.** Stage 2~4를 같은 seed로 ACTIVE/PASSIVE 비교해, 적극 플레이가 더 빨리 끝나고 무고한 격리와 희생을 줄이며 공개 사실·NPC 판단·투표 의향을 직접 바꾸는지 회귀로 고정했습니다.
- **ECHO_WARD는 교집합 추리를 전면에 둡니다.** 한 단서가 바로 한 사람을 알려 주기보다, 서로 다른 출처의 부분 정보를 겹쳐 생각하고 Link/질문으로 그 판단을 방에 표현하게 합니다. 이 규칙은 case 이름 하드코딩이 아니라 authored deduction profile로 정의됩니다.
- **근거 출처가 보입니다.** Link 목록에서 직접 목격, 전언의 원출처, 기록, 공개/개인적으로 들은 정보인지 구분할 수 있습니다. 정답 확률·의심 수치 같은 내부 평가는 보여 주지 않습니다.
- **NPC가 생각을 바꾸면 이유를 말합니다.** 플레이어 개입으로 실제 투표 의향이 바뀐 경우, 숨은 점수 대신 방금 확인된 근거·출처를 짚는 짧은 반응이 나옵니다.
- **Signal Analysis를 마우스만으로 끝낼 수 있습니다.** 주파수와 위상을 슬라이더로 조절할 수 있고 기존 키보드 조작도 그대로 유지됩니다. 네 미니게임 모두 mouse-only 경로를 자동 검증합니다.
- **스크롤이 읽기를 방해하지 않습니다.** 새 줄이 추가되는 동안 위로 휠을 움직이면 예약된 auto-follow가 취소되고 “새 발언 ↓” 표시가 남습니다.
- **1120×700을 정식 검증합니다.** 선택 화면, 대화, 회의, Link 1/2단계, 투표, 용어, 결과, 네 미니게임과 1920↔1120 resize를 모두 검사합니다.
- **회의 행동이 읽기 쉬워졌습니다.** 확인 / 연결 / 개입을 기존 패널 안에서 구분합니다. 관련성이 높은 Link 재료를 위로 정렬하지만 정답만 남기지는 않습니다.
- **반복 Link brute-force를 막았습니다.** 이미 판정한 같은 조합은 다시 눌러도 새 정보를 주지 않습니다. 잘못된 Link는 가능한 경우 같은 출처, 시간 불일치, 원출처 미확인 같은 이유를 설명합니다.
- **역할 하나짜리 공식이 되지 않게 검사합니다.** Null의 거짓 목격뿐 아니라 무고한 사람의 착각·사정·잘못된 전언도 실제로 발생하는지 100-seed fairness audit로 확인합니다.
- **1.0.0 Linux CI 실패를 해결했습니다.** 새 회의 UX를 오래된 `meeting_options()` 하나로만 보던 smoke test를 player-visible action 기준으로 고쳤고 assertion을 약화시키지 않았습니다.

저장 형식은 **Snapshot v4 / meta save v12**를 그대로 유지합니다. Rewind도 Stage당 한 번, 같은 진실, 기억만 유지하는 1.0.0 규칙 그대로입니다.

검증 요약: 40-game official SMART/RANDOM/PASSIVE **93/61/56%**, Stage 2~4 PASSIVE **80/85/75%**. 100-game probe 전체 **93/60/53%**, ECHO_WARD **96/75/81%**. 같은 seed 300쌍 ACTIVE/PASSIVE에서는 세 Stage 모두 ACTIVE가 더 빠르고, 무고 격리·희생이 더 적었습니다. 자세한 수치는 `docs/QA_REPORT.md`에 기록했습니다.

---

# ASTRA 1.0.0 — CONVICTION

**사람의 말을 듣고, 그 말이 왜 맞거나 틀린지 직접 연결하고, 끝내 자기 판단으로 한 사람을 고르는 사회추리.**

- **연결해서 따지기**: 회의에서 누군가의 말(알리바이, 공개된 목격, 해명) 하나와 내가 아는 근거(기록, 목격, 전언, 전문 소견, 다른 사람의 진술, 그 사람의 이전 진술) 하나 — 또는 서로 다른 사람의 근거 둘 — 를 고르면, 게임이 내용만 보고 판정합니다. 같은 것을 보여 주는 근거라면 어느 것이든 통합니다. 맞으면 당사자가 대답하고 방의 판단이 바뀌고, 억지면 신뢰가 조금 줄어듭니다.
- **방은 말해진 문제만 따집니다.** 서로 맞지 않는 알리바이도 누군가 짚기 전에는 판단에 들어가지 않습니다. 묻지 않은 사람의 기록은 회의에 잘 나오지 않습니다. 누구에게 무엇을 물었는지가 결과를 바꿉니다.
- **회의**: 하루 발언 3번 + 확인 질문 3번. 보드는 사람마다 상태를 말로 보여 주고(아직 확인 전 · 후보 중 · 진술이 부딪힘 · 사정이 설명됨…), 회의는 정리로 끝나고, 마지막 말은 실제로 걸린 것에 답합니다. 투표할 때는 이유를 하나 고릅니다.
- **패배해도 이어집니다**: 그날 아침으로 한 번 되감기(같은 진실, 당신만 기억). 이전 STAGE로 돌아가기도 가능합니다.
- **걷기**: 도트 캐릭터 14명이 그려진 다리로 걷습니다. 몸만 흔들리던 움직임을 없애고, 보폭을 캐릭터마다 맞추고, 몸통이 옆으로 튀지 않게 했습니다.
- **탐사요원 선택**: 메인 일러스트만 보여 줍니다. 첫 만남의 분위기는 다음 날까지 이어집니다.
- **배 안의 일**: 신호 분석 · 회로 진단 · 기록 타임라인 · 귀환 경로. 여러 단계의 판단, 시드별 배치, 키보드/마우스, 리셋과 부분 성공.
- **화면**: 새 대사는 끝까지 보이게 따라가고, 지난 대사를 읽는 중에는 끌어내리지 않습니다. 긴 선택지는 잘리지 않습니다.

Snapshot v4 / meta save v12(새 상태는 기존 Stage 상태 안의 선택 필드). 자세한 내용: `docs/GAME_DESIGN.md`, `docs/QA_REPORT.md`, `docs/RESEARCH_100.md`.

---

# ASTRA 0.9.0 — HUMAN VARIABLE

새 캠페인은 여섯 탐사요원 — 세린·미카·제이스·라엘·로건·시아 — 중 한 사람을 고르며 시작합니다. 선택 화면에는 각자의 일러스트와 전신, 갑판에서 걸어 다닐 도트 모습, 지나온 길과 지원 사유, 사람을 대하는 방식이 나옵니다. 능력치나 난이도 표시는 없습니다.

고른 사람에 따라 질문 말투, 승무원과의 첫 주고받음, 회의에서 하는 말이 달라집니다. 사건의 진실·Null·단서·표는 같은 seed라면 누구를 골라도 같습니다. 기존 저장의 이름과 임시 도트 외형은 중립 탐사요원으로 그대로 이어집니다.

도트 캐릭터: 사용자 원본의 걷기·도구 걷기·동작 시트를 모두 새로 잘라 붙였습니다. 14명 모두 인사·놀람·환호·생각·듣기·말하며 손짓·앉기 등 그려진 동작이 있고, 동작마다 걷는 모습과 같은 키·머리 크기로 맞췄습니다. 동작 전후 준비·회복 박자, 걷기 시작·멈춤, 제자리 돌기 전환을 넣어 프레임이 끊겨 보이지 않게 했습니다. 긴 머리·코트가 잘리던 프레임 폭을 넓혔습니다.

회의에서는 결정적 개입을 쓴 뒤에도 공개된 말의 출처를 다시 확인할 수 있습니다(하루 세 번, 강한 개입·EMPATH와 별도). 신호 조율·전력 연결·기록 정렬을 다듬고 시료 비교와 왕복 경로 선택을 추가했습니다.

Snapshot v4 / meta save v12. 자세한 매핑과 검증은 `docs/HUMAN_VARIABLE_090.md`, `docs/PIXEL_ACTIONS_090.md`, `docs/QA_REPORT.md`.

---

# ASTRA 0.8.2 — PLAYER MATTERS

0.8.2는 새 대형 시스템을 추가하는 버전이 아니라 PART I에서 **내가 누구에게 무엇을 물었기 때문에 회의가 달라졌다**는 연결을 더 분명하게 만드는 안정화 패스다.

- 플레이어가 접촉해 얻은 사실은 공개될 때 원래 출처와 접촉 행동을 runtime provenance로 남긴다.
- 단순히 플레이어가 알고 있다는 이유만으로 공개 사실을 플레이어 공으로 세지 않으며, 실제 접촉 또는 직접 공개만 player-caused로 기록한다.
- 회의 개입 전후의 NPC 판단과 투표 의향을 비교해, 플레이어 근거 때문에 실제로 판단이 바뀐 경우를 QA에서 측정할 수 있다.
- 지목은 플레이어가 실제로 알고 있던 근거와 연결되며, 근거 없는 강한 지목 역시 기존 trust/stress/public accusation 경로의 후속을 유지한다.
- Stage 2~4는 ACTIVE/PASSIVE same-seed 비교로 무고 격리, 밤 희생, 해결 속도, 공개 근거, 회의 변화, 투표 변화를 함께 본다.
- 신규 manager, protocol, character, persistent save field는 없다. Snapshot v4 / meta save v12 유지.

---

# ASTRA 0.8.1 — CONTAINMENT TUNING

0.8.1은 새 시스템을 늘리는 업데이트가 아니라 0.8.0의 사회추리 루프를 안정화하는 마감 패스다.

- **Archive 진행 수정.** 실패한 시도는 기록으로 남지만 클리어로 취급되지 않으며, 다음 Stage나 Deep을 열지 않는다. 진행은 저장 슬롯별로 분리된다.
- **프로토콜 선택 수정.** Stage 5는 가디언, Stage 6은 가디언/애널리스트, Stage 7부터 엠패스가 추가된다. 구형 AUDITOR는 화면에 노출되지 않고 호환 입력만 애널리스트로 이관한다.
- **대화가 회의에 더 강하게 연결된다.** 플레이어가 먼저 사람에게서 끌어낸 기록·목격·전언은 회의에서 공개될 가능성이 높고, 아무도 묻지 않은 사적 정보는 자동으로 방 전체의 지식이 되기 어렵다.
- **회귀 검증 강화.** ANALYST 후보 생성/1일 1회 사용, Archive 선택, 실패 후 진행, same-seed player-contact agency, 저장 호환과 UI smoke를 강하게 검사한다.
- **한국어 문구 정리.** 현재 사용되지 않는 구형 조사 기능을 새 해금처럼 안내하던 경로를 숨기고, 프로토콜 설명과 일부 반복 대사를 현재 캐릭터 말투에 맞게 정리했다.

세이브 스냅샷 형식은 v4를 유지한다. 0.8.0 진행과 기존의 정당한 Deep 해금은 보존한다.

---

# ASTRA 0.8.0 — CONTAINMENT

0.8.0은 ASTRA를 **방과 조사 지점을 도는 게임**에서 **사람에게 말을 걸고, 말을 비교하고, 누가 왜 거짓말하는지 가려내는 사회추리 게임**으로 다시 만든 버전이다.

## 무엇이 바뀌었나

**최종 패스에서 달라진 것 (요약)**
- **추리가 공식이 되지 않게.** 하루치 단서가 몇 명까지 좁혀 주는지는 날마다 다르다(첫날은 보통 두세 명). 무고한 사람도 착각해서 잘못 보고, Null도 남의 알리바이를 빌린다. 플레이어 없이 승무원끼리 푸는 비율이 크게 줄었다.
- **전해 들은 말.** 회의에서 누가 “○○가 그랬대”라고 말하면, 본 사람에게 직접 물어 바로잡을 수 있다.
- **탐사요원 등록.** 새 캠페인을 시작할 때 이름과 모습을 고른다(지금은 임시 모습 6종).
- **걷는 장면 9개.** 도트 캐릭터로 작은 방을 걸으며 사람들과 한두 마디 나누고, 신호 맞추기·전력 잇기·순서 맞추기 같은 짧은 일을 함께 한다. 실패해도 막히지 않는다.
- **살아 있는 도트 캐릭터.** 방 안 사람들은 숨 쉬고, 하던 일을 하다가 당신이 다가오면 돌아보고(처음엔 깜짝 놀라며 “!”), 말하면서 고개를 끄덕이고, 일이 잘 풀리면 뛰며 기뻐한다. 라운지에서는 식탁에 앉아 저녁을 먹는다. 그림을 새로 그리지 않고 원래 걷기 그림만 움직여 만들었고, 직접 그린 동작 그림을 나중에 넣으면 그 그림으로 바뀐다.
- **실패와 재시도.** 탐사요원이 쓰러지면 그 재구성은 끝난다. 다시 하면 새 재구성(누가 Null인지도 새로 정해진다)이고, 이어하기는 같은 재구성이다. 다시 시작한 아침에는 당신만 기억하는 한 줄이 남는다.
- **감정 잔향.** 지난 Stage에 일어난 일은 기억이 아니라 느낌으로 가끔 남는다.
- **최종 악장과 심층 재구성.** 마지막 Stage 뒤에 한 가지 결정, 세 갈래 에필로그, 크레딧이 이어지고, 한 목숨으로 끝없이 내려가는 “심층 재구성”이 열린다.


**한 판의 구조.** STAGE 하나가 한 판이고 DAY는 그 안의 라운드다. PART I(STAGE 1~4)은 4명에서 7명까지 한 명씩 깨어나며 Null이 한 명, PART II(STAGE 5부터)는 8명 전원과 Null 두 명, 그리고 전문 프로토콜 하나. 하루는 아침 → 대화 → 회의 → 투표 → 밤이다. 매일 정확히 한 사람이 장기수면 포드로 가고 기권은 없다.

**대화.** 얼굴을 한 번 누르면 바로 대화가 시작된다. 하루에 2~3명만 들을 수 있으니 누구 말을 먼저 들을지가 첫 판단이다. 금색 표시는 오늘 사건과 관련된 일을 맡은 사람. 들은 것에서 나온 질문만 최대 3개가 나오고, 어긋난 말을 들이밀 때 차분히 물을지 몰아붙일지 고를 수 있다. 거짓말한 사람이 전부 Null은 아니다 — 창피함·약속·실수·착각 때문에 숨기는 사람은 믿음을 얻으면 털어놓는다.

**회의.** 사람들이 한 가지씩 논쟁하고 멈춘다: 기록이 공개되고, 지목된 사람이 변명하고, 전문가가 반박하고, Null은 두 번째 변명을 꺼낸다. 멈춘 순간에 맞는 개입을 한 번 할 수 있다(전문가에게 재확인, 목격자에게 되묻기, 감싸기, 당신만 아는 기록 꺼내기, 지목한 사람에게 근거 묻기). 근거 없이 몰아간 사람은 오히려 눈에 띈다.

**사람처럼 판단하는 승무원.** 확신이 없는 사람은 믿는 사람의 말을 따른다. 당신도 그 “믿는 사람”이 될 수 있다. 인물마다 판단 습관과 약점이 있어 틀릴 때도 그 사람답게 틀린다. Null도 원래 말투 그대로 거짓말한다.

**어제가 오늘을 만든다.** 매일 “오늘의 질문”이 전날 결과에서 나온다. 어제 당신이 지목한 사람은 오늘 그 말부터 꺼낸다. 누군가 쓰러지면 가장 가까운 사람이 먼저 흔들리고, 회의는 조용히 시작된다.

**밤과 프로토콜.** PART I의 밤은 자동으로 지나가고 결과는 아침에 사람들이 전한다. PART II에서는 이야기 속에서 프로토콜을 고른다: 가디언(Aegis로 한 사람을 지킴, 2회), 애널리스트(두 말을 정밀 대조), 엠패스(한 번 더 묻거나 한 번 더 말함). 탐사요원이 밤에 쓰러지면 그 STAGE는 실패다.

**화면.** 상단 한 줄(PART·STAGE·DAY, 단계, 깨어 있는 사람)과 지금 할 일 한 줄만 남기고, 설명 팝업·하단 버튼 줄·표시 버튼·힌트 줄을 없앴다. 아침과 결과는 큰 초상화의 장면으로, 대화·회의·투표는 큰 얼굴 중심으로 다시 만들었다. 다음 단계 버튼은 각 화면 안에 하나뿐이고, 할 일이 끝나면 자동으로 넘어간다. 어려운 말은 “용어”(H)에서 쉽게 풀어 준다.

**스토리.** STAGE 1 오프닝에서 5가지(여기가 어디인지, 나는 누구인지, 무슨 일이 생겼는지, Null이 무엇인지, 오늘 무엇을 해야 하는지)를 사람들의 대사로 전하고 “누구 말을 먼저 들어 볼래요?”로 끝난다. 매 STAGE가 왜 새로운 Null로 시작하는지(재동기화, 탐사요원만 기억함)를 STAGE 2에서 짧게 설명한다. PART II 전환은 마렌 각성·8인 전원·‘19년 전 도착’ 기록·Null 두 갈래·Aegis 복구를 한 장면으로 묶었다. 0.7.x의 장면 일러스트가 결말 장면에 다시 쓰인다.

**아트.** 세나와 마렌을 새 원화로 전면 교체했고, 여덟 명 전원의 이미지 세트를 원화 비율 그대로 다시 잘랐다.

## 저장

새 캠페인은 항상 STAGE 1·DAY 1·4명부터 시작한다. 진행은 저장 슬롯마다 따로 기록된다. 0.7.x 저장은 열 수 있고, 탐색/조사 단계에 있던 저장은 대화 단계로 이어진다. 감사관(AUDITOR) 프로토콜은 애널리스트로 바뀐다.

---

# ASTRA 0.7.4 — PLAYBACK

0.7.4는 콘텐츠 추가보다 **장면 사이의 연결과 플레이 후 잔향**을 다듬는 버전이다. 기존 CLEAR SIGNAL scheduler의 continuation/focus-family/speaker-exposure, HUMAN TRACE/HUMAN AFTERMATH consequence, chapter progression을 그대로 사용한다.

첫 0.7.4 패스에서 player-visible high-salience beat 직후 unrelated Dynamic Incident를 한 action 늦추는 breathing room을 추가했다. completion pass에서는 이 guard가 MANDATORY/FOLLOWUP/FOCUS 모두에 적용되면서도 플레이어가 직접 인물을 찾아가거나 topic을 선택하는 행동은 계속 허용되는지 회귀로 고정했다. micro-arc 선택 → delayed consequence → authored callback도 기존 queue를 통해 실제 도달 가능한지 검증한다.

추가로 ACT II의 `RESET_FRAMING` 누락을 수정했다. 이전에는 SECOND_WATCH 이후 결과 화면이 CALIBRATION의 “같은 목소리/반창고” 문구로 fallback했지만, 이제 ACT II 여섯 장이 각 장의 실제 발견을 짧은 residue로 남긴다. LAST_LIGHT → SECOND_WATCH → THRESHOLD 슬롯 progression, Night의 즉시 consequence / Briefing의 지속 social interpretation 역할 분리도 PLAYBACK gate에 포함했다.

신규 authored scene **0**, 삭제 scene **0**, 신규 visual asset **0**, 신규 persistent field **0**, save schema **v11 유지**. art071/art072/art073의 기존 15개 visual mapping과 FIRST IMPRESSION을 유지하며 새 manager를 만들지 않았다.

# ASTRA 0.7.2 — ACT I VISUAL STORY PASS

ACT II의 다섯 이미지에 이어 ACT I에서 플레이어가 오래 기억해야 할 다섯 순간을 같은 비모달 stage 방식으로 시각화했다. CALIBRATION은 첫 각성의 정상적인 의료실과 비어 있는 실행 기록, ECHO_WARD는 소렌의 파형 검증, SILENT_ORBIT은 정지한 별과 정상적인 도착/정비 기록, RED_SHIFT는 오래된 시료 라벨과 현재의 필기 습관, LAST_LIGHT는 서로 모순되지만 각각 검증되는 기록을 한 화면에 잡는다.

DEAD_AIR는 두 유효 목적지 문서라는 구도가 LAST_LIGHT와 겹쳐 이번 패스에서는 제외했다. 이미지는 결론을 대신하지 않으며, 대사는 그림을 낭독하지 않고 인물의 검증 과정과 판단을 담당한다. 기존 canon, ACT II, handling choice, progression, save schema v11은 그대로다.

기술적으로는 0.7.1의 `AstraArt` 매핑과 `AstraVoyageView` stage를 재사용한다. 신규 컷신/아트/save 시스템은 없다. 0.7.0의 CI 직접 실행 누락 테스트도 함께 연결했으며 0.7.2 전용 visual story 회귀를 추가했다.

# ASTRA 0.7.1 — VISUAL STORY PASS

## ACT II의 다섯 장면을 실제로 보이게

0.7.1은 새 시스템 버전이 아니다. 0.7.0에서 이미 완성한 ACT II 진행과 사회추리/생활 시스템을 유지하면서, 플레이어가 기억해야 할 다섯 resolution에만 장면 이미지를 넣는 소규모 패스다.

- **SECOND_WATCH** — 오래된 근무 로그와 반복되는 정상 교대 흔적
- **BLIND_DECK** — 지도에서만 사라진 서비스 갑판과 실제 사용 마모
- **THREE_MINUTES_DARK** — 비상등 아래 동시에 갈라지는 세 개의 문제와 정보 출처
- **CONTINUITY** — 식사·진료·정원 관리처럼 너무 평범해서 이상한 생활 기록
- **THRESHOLD** — 정상 생활 기록이 끊기고 긴 공백 뒤 장기수면 재개로 이어지는 전환

이미지는 인물 얼굴을 새로 정의하는 CG가 아니라 저채도 공간/UI형 키아트다. 기존 초상화와 충돌하지 않으며, resolution이 끝나면 즉시 평소 room art/portrait 흐름으로 돌아간다. 이미지가 없는 장면도 기존 fallback으로 그대로 동작한다.

장면 텍스트도 함께 손봤다. 그림에 보이는 내용을 대사로 다시 낭독하기보다 승무원들이 그 흔적에서 무엇을 받아들이는지에 초점을 맞췄고, THRESHOLD는 최종 원인을 설명하지 않고 “왜 다시 잠들었는가”를 다음 질문으로 남긴다. save schema는 **v11 유지**, migration 없음이다.

# ASTRA 0.7.0 — SECOND WATCH

## ACT I 재구축, ACT II 신설

0.6.2까지의 캠페인은 사건 자체는 좋지만 Day 1~3에 선택적 pair/observation 장면이 전혀 없어 “7개의 큰 단서를 빠르게 확인했다”는 체감이 강했다. 이번 버전은 그 문제를 구조부터 다시 짰다: CALIBRATION의 authored `trace_steps: 1`을 무시하고 항상 2로 덮어쓰던 버그를 고치고, Day 1~5의 자기소개 대사(“저는 의무관 미라예요”)를 비모달 FIRST IMPRESSION 표시로 대체하고, Day 2(투아·다렌 cross-check)·Day 3(준/세나 병렬 관찰)에 새 장면을 추가했다. Day 4~6의 RESOLUTION_BEATS도 더 깊어졌다: 소렌의 자기 목소리 분석은 이제 전문적 청취 근거를 먼저 보여 준 뒤에야 부정하기 어려워지고, SILENT_ORBIT은 세 번째 근거(system time)와 평범한 정비 기록을 더하고, RED_SHIFT의 “내 필체” reveal은 단발성 대사가 아니라 실제 beat가 됐다.

LAST_LIGHT 다음에는 ACT II — SECOND WATCH · BORROWED DAYS · BLIND DECK · THREE MINUTES DARK · CONTINUITY · THRESHOLD 6일이 새로 이어진다. 도착 이후에도 승무원들이 정상적으로 근무하고 생활했다는 기록을 조사하며, THRESHOLD에서 “적어도 일부 history에서는 도착 이후 정상적으로 살다가 다시 장기수면에 들어갔다”는 새 사실을 확인하고 다음 질문(왜 다시 잠들었는가, 누가 그 잠을 시작했는가)을 남긴 채 끝난다. ACT III는 만들지 않는다.

## 새로 만들지 않고 확장한 것들

개발 전 실제 리포지토리를 감사한 결과 Knowledge/Decision/Routine/Consequence/Motive/Incident/Codex/Claim Ledger 같은 서사 지원 시스템과, 8명 전원의 4단계 개인 micro-arc가 이미 구현되어 있었다. 새 manager는 만들지 않고 다음만 확장했다: storylets_052~055.gd의 MID_CHAPTERS/LATE 게이트와 incident_model.gd의 모든 incident에 ACT II 6일을 추가해 기존 608개 라이브러리와 8종 incident가 LAST_LIGHT 이후에도 계속 등장하게 했고, `AstraCrewCatalog.PAIR_CANDIDATES`에 이전까지 대사가 전혀 없던 4개 조합(준-소렌, 세나-노아, 마렌-소렌, 루칸-노아)을 추가했다. ACT는 저장 값이 아니라 campaign day에서 파생되므로(`AstraVoyageContent.act_for`) save schema는 **v11**을 그대로 유지한다.

개발 중 실제로 발견해 고친 버그가 하나 있다: ACT II 6일의 fact에 새 문자열을 썼다가, investigation point가 `AstraVoyageContent.ROOMS`의 고정된 8개 공유 태그만 사용한다는 사실을 몰라 goal_done이 영원히 true가 되지 않는 문제를 전체 캠페인 UI 구동 검증으로 발견하고 고쳤다. 재발 방지 회귀 테스트를 추가했다.

authored voyage/reactive library는 **622개**(신규 14개)이며, 정식 Windows packaging과 v0.7.0 tag, GitHub Release는 사용자 요청 전까지 보류한다.

# ASTRA 0.6.2 — HUMAN AFTERMATH

0.6.1 HUMAN TRACE의 후속 패스다. 새 대형 시스템이나 scene pack 대신 기존 resolution reaction, next-loop residue, story hook의 역할을 분리했다. player-facing primary owner를 명시해 같은 consequence를 여러 surface가 설명하는 방향을 피하고, residue에는 실제 source handling tag를 남겨 다음 loop callback의 provenance를 검증할 수 있게 했다.

callback/reaction/hook은 기존 Storylet Scheduler가 continuation으로 인식할 수 있는 metadata를 사용한다. hidden Null, hidden motive, raw relationship는 selector input에 추가하지 않았다. authored voyage/reactive library와 save schema v11은 그대로 유지한다.

정식 Windows packaging, v0.6.2 tag, GitHub Release와 release asset upload는 이번 개발 단계에서 생성하지 않는다.

후속 검증에서 500-loop HUMAN AFTERMATH simulation과 실제 authored text 기반 editorial report, 1366×768/1920×1080 전용 aftermath UI smoke를 추가했다. 이 과정에서 RED_SHIFT next-loop residue의 행동 주체는 노아인데 base resolution speaker가 남아 초상/화자가 어긋날 수 있는 경로를 발견해 callback의 visible speaker를 authored 행동과 일치시켰다. 최종 보완 CI run `35679587205`에서 Linux/Windows가 모두 GREEN이며 HUMAN AFTERMATH **150 checks**, simulation **13 checks**, duplicate feedback 0, ordinary optional starvation 0, unreachable callback ID 0을 기록했다.

# ASTRA 0.6.1 — HUMAN TRACE

## 발견한 사실을 어떻게 다뤘는가

DEAD AIR부터 LAST LIGHT까지 핵심 사실은 기존 canon 그대로 유지된다. 대신 각 resolution에 장별 authored choice를 추가해 공개, 보존, 재검증, 분리, 개인 사본 같은 처리 방식을 플레이어가 고른다. 선택은 새 분기 엔진이 아니라 기존 voyage choice pipeline과 memory tag, DialogueMemory, KnowledgeModel, evidence ownership, consequence 경로를 사용한다.

선택 뒤에는 가능한 경우 한 명의 짧은 reaction만 보여 주고 기존 story hook으로 돌아간다. 다음 loop callback도 NPC가 과거 loop를 초자연적으로 직접 기억하는 방식이 아니라, 기록을 놓는 습관이나 익숙한 확인 순서처럼 작은 residue로 표현한다. canonical resolved fact, chapter order, LAST_LIGHT의 multiple-valid-history canon과 Player != Null 조건은 바뀌지 않는다.

반복 resolution은 첫 경험을 압축하지 않는다. 이미 본 동일 resolution은 기존 scene_seen_counts와 full-scene payload를 이용해 결론 설명만 줄이고, 이번 loop의 handling choice와 새 callback/reaction은 정상 속도로 남긴다.

## 개발/배포 분리

Windows release workflow의 main-push 자동 실행을 제거했다. 일반 Godot CI와 Windows validation은 개발 PR/main에서 계속 수행하지만, packaging/tag/GitHub Release는 v* tag 또는 명시적 workflow_dispatch 시점까지 보류한다.

Save schema는 실제 최신 main의 **v11**을 유지하며 신규 migration은 없다.

## 개발 검증

GitHub Actions run **#536** (`35673297533`), commit `51e2d82c4e426ab6b165b25ce244d468f3caba88`에서 Linux/Windows validation이 모두 GREEN이다. HUMAN TRACE **326 checks**, core model **49,255 checks**, campaign **106**, voyage **656**, story consistency **419**, FIRST CONTACT **259**, reset **22**, NPC vote regression **19,086**을 통과했다. `--games=40`은 smart **79%** / random **19%** / passive **0%**, content audit은 **0 FAIL / 1 WARN**이다.

Windows packaging / Git tag / GitHub Release는 개발 정책에 따라 실행하지 않았다.

---

# ASTRA 0.6.0 — FIRST CONTACT / STORY LOOP

## 첫 접촉에서 다음 질문까지

0.6.0은 새 버전을 더 올리는 업데이트가 아니라, FIRST CONTACT와 story/loop integration을 배포 가능한 상태로 완성한 릴리스입니다. CALIBRATION은 미라·준·다렌·노아 4인으로 시작하며 포드 제어 패널을 직접 조사해야 핵심 발견이 완료됩니다. 방을 반복 이동하는 것만으로 discovery가 끝나지 않습니다.

FIRST CONTACT 전용 choice routing은 `first_panel`에만 적용되고, 이후 authored choice는 일반 voyage pipeline을 사용합니다. 승무원은 항해 Day 2~5에 순차 합류하며 ballot은 unselected / abstain / target을 구분합니다.

각 장은 situation과 직접 발견 뒤 local resolution/reaction을 실제 플레이에서 경험하고, resolved fact / open question / next hook을 남깁니다. LAST_LIGHT는 서로 다른 유효 history가 공존하며 현재 Null 사건만으로 전체 모순을 설명할 수 없다는 canon을 유지합니다. Player != Null입니다.

## 회귀 복구

CI #516의 voyage regression 두 실패는 기능 삭제나 assertion 완화 없이 현재 런타임 순서에 맞춰 복구했습니다.

- ECHO_WARD recorder: `voyage_use_recorder()`가 `voyage_backup`을 남기고 실제 chapter investigation 완료 후 `finish_voyage()`가 `mission_backup`으로 전달하는 경로를 검증합니다. contact-flow에서 goal hint가 더 이상 fact를 자동 지급하지 않으므로 테스트도 실제 `signal` 조사 지점을 검사합니다.
- DEAD_AIR + Mira 100-seed variety: DEAD_AIR의 첫 각성자가 Sena로 바뀐 뒤 Mira를 만나지 않은 상태에서 `voyage_talk("mira")`를 호출하던 오래된 테스트 흐름을 실제 visit → awakening close → ordinary talk 순서로 정합화했습니다. 최소 3개 scene ID 요구는 그대로 유지합니다.

## 0.6.0 release gate

GitHub Actions run **#518** / Godot 4.7.2 stable:

- Linux import / parse: PASS
- Windows validation / UI smoke / main boot: PASS
- voyage: **649 checks PASS**
- story consistency: **407 checks PASS**
- FIRST CONTACT: **259 checks PASS**
- reset safety: **22 checks PASS**
- NPC vote regression: **19,086 checks PASS**, 4,200 ballots, invalid/self/empty-reason 0
- `--games=40`: smart **79%** / random **19%** / passive **0%**
- content audit: **0 FAIL / 1 WARN**
- authored voyage/reactive scenes: **608**

정식 Windows ZIP/SHA256과 GitHub Release provenance는 main 병합 및 tag-source 빌드 완료 후 QA_REPORT에 최종 기록합니다.

---

# ASTRA 0.5.7 — CLEAR SIGNAL

## 덜 많이, 더 선명하게

CLEAR SIGNAL은 콘텐츠를 줄이는 업데이트가 아닙니다. 608개의 authored voyage/reactive scene은 그대로 두고, 한 loop에서 서로 상관없는 중요한 이야기가 동시에 너무 많이 열리지 않도록 선택 흐름을 정리했습니다.

이미 시작된 이야기는 이어지기 쉬워집니다. 실제 follow-up과 consequence, mandatory progression, 현재 보이는 continuation은 새 이야기 하나로 다시 세지 않습니다. 플레이어가 topic을 직접 고르거나 Notebook에서 질문을 pin한 경우도 계속 따라갈 수 있습니다.

반대로 이미 두 개의 high-salience thread가 보이는 상태에서 관련 없는 세 번째·네 번째 이야기는 soft weight가 낮아집니다. 완전 차단이 아니기 때문에 플레이 패턴과 조건에 따라 드물게 더 많은 스레드가 나타날 수 있습니다.

## Player-safe focus

focus selector가 보는 것은 현재 loop에서 실제로 노출된 family/event, 최근 focus, 화자 노출 횟수, explicit topic과 pinned question뿐입니다. Null 정체, hidden motive, raw relationship 수치처럼 플레이어가 모르는 정보로 서사 선택을 조종하지 않습니다.

미라의 optional exposure max 4는 유지합니다. 같은 화자에게 optional scene이 몰릴 때는 speaker exposure로 완화하고, dense loop의 두 번째 autonomous beat는 삭제하지 않고 뒤로 미룹니다.

## 500-loop release gate

최종 구현 검증 결과:

- high-salience distinct families: 평균 **2.22** / P95 **3** / 최대 **4**
- unrelated new-thread 4+: **11 / 500**
- visible continuation: **10**
- zero-meaningful consecutive: **0**
- visible signatures: **500 / 500**
- autonomous unique: **23**
- 0.5.3 authored coverage: **59.3%**
- rare immediate repeats: **0**
- Mira optional exposure max: **4**
- CLEAR SIGNAL invariants: **47 checks PASS**
- runtime exposure simulation: **10 checks PASS**

신규 authored voyage scene은 **0개**, 전체 library는 **608개**, save schema는 **v10** 그대로입니다. 첫 30분의 CALIBRATION/DEAD AIR 학습 구조에도 새 시스템 설명이나 필수 텍스트를 추가하지 않았습니다.

공식 `v0.5.7` tag-source Windows run `35575857561`은 `ASTRA-0.5.7-windows.zip`을 생성했고 exported EXE boot까지 통과했습니다. 파일 크기는 **92,844,194 bytes**, 공식 Release SHA-256은 `5ea10cb171ce3d42e66da54c3c14d2adff6f9648a3d86e8166146c016a0846ec`입니다. 이전 RC run `35573583450`의 `a9d1...` hash는 사전 RC provenance로 `docs/QA_REPORT.md`에 보존합니다.

---

# ASTRA 0.5.6 — ECHOES

## 선택과 관계의 변화가 읽힌다

기존 시스템의 내부 수치를 더 공개하는 대신, 플레이어가 실제로 목격했거나 플레이어 행동으로 생긴 변화만 짧은 인간 언어로 보여 줍니다. trust +0.05, hidden motive, Null probability 같은 내부 값은 표시하지 않습니다.

밤과 다음 날 브리핑의 역할도 나눴습니다. 밤은 즉시 consequence, briefing은 계속 남은 관계/판단의 여파를 담당해 같은 social feedback을 연속 화면에서 되풀이하지 않습니다.

## Observation Codex

Crew Archive에는 32개의 authored observation이 있습니다: STABLE 14 / OBSERVED 10 / ECHO 8. 8명 모두 4개씩이지만 수치보다 실제 경험 기반 해금이 우선입니다.

Codex는 정답지가 아닙니다. 실제 awakening, 실제 authored scene, 실제 visible relationship milestone처럼 플레이어가 본 근거만 기록합니다. hidden relationship score, motive, Null state, candidate storylet만으로는 해금하지 않습니다.

Notebook은 현재 항해의 질문·사실·관계 관찰을 위한 working memory이고, Crew Archive는 여러 항해를 거쳐 실제 목격한 모습이 남는 장기 기억입니다.

## 첫 플레이와 저장

CALIBRATION의 필수 흐름은 전원 패널 확인 → 미라와 직접 대화 그대로입니다. 첫판에서 여러 observation이 생겨도 연속 Codex toast를 띄우지 않고 조용히 archive에 기록합니다.

save schema는 v10을 유지하며 v9와 더 오래된 저장을 destructive reset 없이 읽습니다. resume 시 이미 meta에 저장된 Codex 항목은 pending에서 제거해 같은 scene을 다시 만나도 toast/result의 "새 기록"이 중복되지 않습니다.

## Content & QA

신규 authored voyage scene: **0**  
전체 authored voyage/reactive library: **608**  
캐릭터별 scene: 미라 98 / 준 81 / 다렌 74 / 노아 79 / 세나 71 / 소렌 64 / 루칸 62 / 마렌 79  
Codex: **32** (STABLE 14 / OBSERVED 10 / ECHO 8)

전용 테스트: Codex **95 checks**, ECHOES **33 checks**. Linux/Windows validation과 Windows release-candidate pre-build에서 모두 실행합니다.

---

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
