# 1.0.0 CONVICTION — LOCAL VALIDATION — 2026-09-26

기준: `main` 2f0fc5a (v0.9.0) · branch `astra-1.0.0-conviction` · VERSION **1.0.0** · Snapshot **v4** · Meta save **v12** ·
migration 없음(새 상태 `links`, `raised_pairs`, `ballot_reasons`, `null_plans`, `explorer_tones`, `rewinds`, `echo_notes`, `echo_leads`,
`sourced`, `tone_recalled`는 모두 기존 `flags["stage_080"]` 안의 선택 필드이며 없으면 기본값. 되감기용 아침 스냅샷은 같은 v4 형식의 별도 파일).

## 변경 전 기준선(0.9.0, 40판 공식 게이트)
SMART 92% · RANDOM 67% · PASSIVE 63% · Stage 2~4 PASSIVE 87/95/97% · 기여 1.70 vs 0.66.
원인 계측(tests/_tmp 프로브, 비 CI): PASSIVE는 1일차에 대부분 틀리지만(무고/희생양 격리 ~75%) 2~3일차에 방이 스스로 수렴했다.
수렴 경로: 보드의 알리바이 충돌을 모든 NPC가 조용히 반영, 혼자 가진 좁혀진 목격으로 공개 지목 → 방이 따라감, 묻지 않은 기록의 자동 공개.

## 결과 (1.0.0)
### 공식 게이트 (40판/Stage, `run_tests.gd`, 로컬 Windows) — `ASTRA TESTS OK · 63,700 checks`
TOTAL SMART 91% · RANDOM 68% · PASSIVE 55% · PART II SMART 88% / PASSIVE 47% · Stage 2~4 PASSIVE 80% (75/82/82) ·
공개 기여 SMART 5.90 vs PASSIVE 1.36 (0.9.0: 1.70 vs 0.66).
Stage별 SMART/RANDOM/PASSIVE: CALIBRATION 100/77/60 · DEAD_AIR 95/90/75 · GLASS_GARDEN 100/87/82 · ECHO_WARD 100/85/82 · SILENT_ORBIT 92/65/42 ·
RED_SHIFT 85/67/50 · LAST_LIGHT 82/52/40 · SECOND_WATCH 90/57/52 · BORROWED_DAYS 90/52/50 · BLIND_DECK 90/67/60 · THREE_MINUTES_DARK 90/67/47 ·
CONTINUITY 87/52/32 · THRESHOLD 92/65/50.
Agency (8 paired seeds, ACTIVE/PASSIVE): DEAD_AIR 승 7/6 · 일수 11/15 · 무고 격리 4/9 · 희생 4/9 · 공개 11/0 · 회의 변화 8/0 · 투표 변화 14/0 —
GLASS_GARDEN 8/6 · 11/18 · 3/12 · 3/10 · 20/0 · 15/0 · 25/0 — ECHO_WARD 8/7 · 10/24 · 2/17 · 2/17 · 14/0 · 17/0 · 22/0.
나머지: motion 1,699 · minigame 545 · deduction 9,955 · UI layout 815 · pixel 1,711 · 0.9.0 variable 1,055 · campaign 219 · deep 66 · agency 66 · UI smoke · walkthrough 080/100 · 보존 스위트 전부 PASS (`tests/ci_suite.txt` 29개).
### 대표본 (100판/Stage, `balance_probe.gd --games=100`, 공식 게이트와 다른 seed)
| Stage | SMART | RANDOM | PASSIVE |
|---|---|---|---|
| CALIBRATION | 98 | 83 | 57 |
| DEAD_AIR | 93 | 72 | 67 |
| GLASS_GARDEN | 99 | 86 | 73 |
| ECHO_WARD | 95 | 84 | 85 |
| SILENT_ORBIT | 94 | 64 | 50 |
| RED_SHIFT | 85 | 61 | 36 |
| LAST_LIGHT | 91 | 57 | 48 |
| SECOND_WATCH | 98 | 58 | 50 |
| BORROWED_DAYS | 91 | 55 | 44 |
| BLIND_DECK | 84 | 60 | 48 |
| THREE_MINUTES_DARK | 92 | 60 | 43 |
| CONTINUITY | 85 | 56 | 45 |
| THRESHOLD | 88 | 62 | 44 |
| **전체** | **91** | **66** | **53** |

- SMART − RANDOM 25점, SMART − PASSIVE 38점(0.9.0: 25 / 29).
- Stage 2~4 PASSIVE 평균 75%(0.9.0 ≈ 93%). **권장 목표 60%에는 도달하지 못했다.** ECHO_WARD(7명, 목숨 3~4번)는 85%로 남았다:
  방이 틀려도 기회가 여러 번이고 3일차에는 흔적이 한 사람으로 좁혀지는 구조 때문이다. NPC를 멍청하게 만들거나 단서를 무작위로 숨기는 방식은 쓰지 않았다.
- 같은 seed 짝 비교(agency, 8 seeds × Stage 2~4): 아래 CI 절의 AGENCY 줄. 적극 플레이는 무고한 격리·희생·경과 일수를 크게 줄인다.

### 1.0 게이트 (기존 0.8 게이트는 그대로 두고 추가)
SMART ≥ RANDOM + 15 · SMART ≥ PASSIVE + 20 · Stage 2~4 PASSIVE ≤ 85% · 공개 기여 SMART > PASSIVE × 3.
85%는 0.9.0 실측(93%)보다 낮고 이번 분포(40판 80%, 100판 75%)의 여유를 둔 값이다.

## 새 자동 검증
- `motion_100_tests.gd`: 14명 × 4방향 × (걷기, 도구 걷기) — 연속 프레임 하체 차이 ≥ 40px, 한 바닥선, 키 ≤ 12px, 몸통 축 ≤ 3px, 보폭 56–112px, 한 보폭 = 한 사이클, 막히면 제자리, 걷는 동안 띠 이동 0, 90°/180° 전환, 줄인 움직임에서도 걷기, 전환 중 빈 프레임 없음.
- `minigame_100_tests.gd`: 네 계열 × 16 seed — 결정적, 답이 seed마다 다름, 키보드만으로 성공, 부분 성공, 잘못된 단계는 설명되고 막히지 않음, 완료 1회, 모든 인터루드가 네 계열 중 하나, 역할을 말하지 않음. 회로: 측정 3번이면 언제나 고장 모듈이 특정됨(공정성).
- `deduction_100_tests.gd`: 4 Stage × 12 seed 회의 — 모든 연결 판정에 이유, 근거는 플레이어가 아는 것만, 맞는 연결 194건 중 같은 진술에 동등한 근거가 둘 이상 성립 41건, 무관 2,132건 거절, 확인 질문 7종, 교집합·좁힘, 연결 후 당사자 대답과 방의 반응, 회의 정리, 마지막 말, 투표 이유 저장, NPC 투표 이유 문장. "말해진 문제만" 규칙, 혼자 본 것 규칙, 되감기(같은 진실, 기억 ≠ 지식), 선택 화면(도트 없음, 같은 일러스트의 카드).
- `ui_layout_100.gd`: 1366×768 · 1600×900 · 1920×1080 · 2560×1440, 합성 긴 한국어 — 마지막 대화/회의 줄이 휠 없이 보임, 아래 여백, 과거를 읽는 중에는 끌어내리지 않고 "새 발언" 칩, "끝까지 보기" 후 마지막 줄, 줄바꿈 버튼 높이, 창 밖으로 나가는 텍스트·버튼 없음, 투표 확정 버튼, 실제 앱 경로의 되감기(아침 보관 → 패배 → 되감기 → 같은 진실 → 한 번만).
- `walkthrough_100.gd`: Stage 1·2·3·5·9·13 전체 흐름 + 같은 seed의 세린·미카·로건 비교 → `build/qa/walkthrough_100.txt`.

## 사람이 본 것 (창 모드 캡처, `tests/visual_100.gd` → `build/qa/100/`)
- 선택 화면(세린·로건, 두 해상도): 도트 없음, 카드 = 메인 일러스트 크롭, 잘림 없음.
- 걷기 스트립(14명, 1x·3x·다리만 3x): 네 방향 모두 발이 교대로 나감을 확인. 시퀀스(출발→한 보폭→정지→뒤돌기→말하기).
- 회의(시작·연결 선택 1/2·2/2·연결 후·정리), 투표(이유 선택), 패배 결과, 작업 네 계열.
- 발견해서 고친 것: 목표 문구가 옛 규칙("한 번 끼어드세요"), 내레이션 뒤 "· 의 말에" 빈 이름, 동행 충돌이 한쪽만 표시, 설명된 충돌이 계속 의심을 만듦, "루칸였어요" 조사, "마렌은 마렌의 선실" 표현, 신호 분석 1단계가 너무 쉬움(깨끗한 사인파) → 모든 채널에 잡음과 비반복 간섭.

## 남은 것
- Stage 2~4 PASSIVE 60% 목표 미달(75%, ECHO_WARD 85%).
- 실제 사람의 플레이 감각(재미, 회의 템포, 연결 선택지 목록의 길이)은 자동 검사로 판정하지 않는다.

---

# 0.9.0 HUMAN VARIABLE — LOCAL VALIDATION — 2026-09-25

기준: `main` 9ed806c (v0.8.2) · branch `astra-0.9.0-human-variable` · VERSION **0.9.0** · Snapshot v4 · Meta save v12 · migration 없음
(새 필드 `explorer_id`/`art_id`는 기존 프로필 dictionary 안의 선택 필드, 기존 p1–p6 저장은 중립 탐사요원으로 로드).

## 이번 패스에서 바로잡은 것
- 이전 0.9.0 초안은 탐사요원 초상화를 **생성 이미지**(`assets/player_src/*_portrait.png`)로 넣고, 도트를 임시 외형 p1–p6에
  임의로 묶어 두었다(세린=p2 등). 사용자가 넣은 `플레이어/` 전신 6장·표정 시트 4장과 `미니 도트 캐릭/<이름>*.png`는 쓰이지 않았다.
  생성 이미지를 제거하고 여섯 명 모두 사용자 원본으로 교체했다(`tools/import_explorers_090.gd`, `tools/import_pixel_090.gd`).
- 새로 추가된 승무원 동작 시트(`<이름>1.png`, `<이름>2.png`, 16장)가 게임에서 쓰이지 않았다 → 176개 포즈 칸으로 연결.
- `루칸1.png`(소렌 그림)·`소렌2.png`(루칸 그림) 이름 뒤바뀜을 그림 기준으로 매핑.
- 미카·라엘·시아 걷기 시트의 옆모습 두 줄이 같은 방향 → 왼쪽은 좌우 반전으로 생성.
- 96px 폭에서 긴 머리·코트가 잘리던 걷기 프레임(0.8 importer 경고 40여 건) → 128px, 잘림 0.
- 대화·회의에서 탐사요원 얼굴이 일러스트 머리(같은 원본)로 표시됨. 기록 열기·압박 대사도 탐사요원 말투.

## 자동 검증 (Windows 로컬, Godot 4.7.2, `tests/ci_suite.txt` 22개 전부)
- `ASTRA TESTS OK · 61,840 checks` (40 games/Stage). 기준치 변경 없음:
  TOTAL smart **92%** · random **67%** · passive **63%** · PART II smart 90% / passive **53%** ·
  기여 smart 1.70 공개 사실/게임 vs passive 0.66.
- Stage별 smart/random/passive: CALIBRATION 100/70/65 · DEAD_AIR 95/82/87 · GLASS_GARDEN 100/87/95 · ECHO_WARD 95/95/97 ·
  SILENT_ORBIT 100/70/57 · RED_SHIFT 90/57/55 · LAST_LIGHT 92/40/40 · SECOND_WATCH 87/55/65 · BORROWED_DAYS 87/57/37 ·
  BLIND_DECK 92/70/65 · THREE_MINUTES_DARK 92/77/52 · CONTINUITY 80/65/50 · THRESHOLD 92/55/55.
- Stage 2~4 paired agency (8 seeds): ACTIVE/PASSIVE 승리 7/7·8/8·8/8, 경과 일수 합계 11/14·13/17·13/18, 무고한 격리 합계 4/7·5/9·5/10,
  희생 4/7·5/9·5/10, 공개 사실 11/0·22/0·20/0, 회의 판단 변화 8/0·10/0·16/0, 투표 의향 변화 9/0·14/0·23/0.
- `ASTRA HUMAN VARIABLE 090 TESTS OK · 1,176 checks`: 같은 seed·다른 탐사요원 → packet·Null 동일, 여섯 가지 실제 대화/회의 문장,
  저장·복원, 여섯 명 모두 전신·머리·흉상 5 mood·도트·얼굴 존재, 탐사요원 도트 4프레임 보행, 레거시 p1–p6 중립 유지.
- `ASTRA PIXEL 080 TESTS OK · 1,711 checks`: 20개 걷기 시트(승무원 8·탐사요원 6·레거시 6) 모든 칸 비어 있지 않음·발 바닥,
  14명 포즈 시트의 모든 칸 비어 있지 않음·바닥·걷기 인물보다 크지 않음, 준비/회복 박자, 제자리 돌기, 멈춤 settle, 말하기 손짓,
  줄인 움직임.
- UI smoke OK (첫 의미 있는 선택 17클릭, 첫 투표 24클릭), campaign 219, deep 66, agency 66, walkthrough 2,479줄, 나머지 보존 suite 전부 PASS.
- 변환 감사(`assets/pixel080/manifest.json`): 포즈 176칸, 잘림 0, 걷기 한 방향 안에서 머리 끝 흔들림 ≤ 4px(0–1px 78/104 방향).

## 시각 확인 (창 모드)
- `visual_human_090.gd` OK: 선택 화면 6명 × 1366×768·1920×1080(카드·시작 버튼 화면 안), 14명 × 두 해상도 동작 시트
  (모든 걷기 프레임, 띠 동작, 전환, 포즈) → `build/qa/explorer090_*`, `build/qa/motion090_*`.
- `visual_life_080.gd` OK: 탐사요원(세린·라엘)으로 방 입장·알아챔·대화·과제 완료(그려진 환호)·저녁 식탁(그려진 앉은 자세).

## 남은 한계 (사람이 판단할 것)
- PART I Stage 2~4 PASSIVE 승률은 여전히 높다(87/95/97%). 이번 패스는 그림·동작·정체성 연결이 중심이고 증거 곡선은 바꾸지 않았다.
  대신 ACTIVE는 같은 seed 8개 합계로 3~5일 빨리 끝나고, 무고한 격리와 희생이 3~5명 적다.
- 동작 시트 중 제이스·라엘은 걷기 시트보다 머리를 크게 그린 편이라(머리 폭 비율 0.75~0.77) 포즈에서 머리가 걷기보다
  약간 커 보일 수 있다(키 기준으로 맞추고 머리 폭을 25% 반영).
- 대사 자연스러움·재미는 자동 검사로 판정하지 않는다. `build/qa/walkthrough_080.txt`의 세린/미카 비교 구간을 읽어 볼 것.

---

# 0.8.2 PLAYER MATTERS — FINAL VALIDATION — 2026-09-25

기준 main 시작점: `f0ff5a97c49f7d1e5404db16df91145d270d0fcb`  
검증 branch: `astra-0.8.2-player-matters`  
검증 commit: `22e66888cb1a17dbb77586e923c26cfb28f27afe` (PR #20, merge 전)  
VERSION: **0.8.2** · Snapshot v4 · Meta save v12 · migration 없음.

## Functional
- 0.8.1의 progression / slot isolation / protocol fixes를 그대로 유지하며 새 mode, character, protocol, Act, ending은 추가하지 않음.
- player contact → public fact → meeting opinion shift → NPC vote-intention change를 runtime provenance로 추적.
- player-caused public fact는 **실제 대화 접촉으로 해당 사실을 끌어냈거나 플레이어가 직접 공개한 경우만** 인정. 단순히 플레이어가 알고 있다는 이유만으로 인과를 과대계상하지 않음.
- 플레이어 지목의 `basis_facts`는 대상의 suspicion breakdown에 실제 양(+)의 근거로 기여한, 플레이어가 알고 있는 fragment id만 보존.
- 기존 Snapshot v4는 agency 필드가 없어도 lazy default로 로드되며 schema bump가 필요하지 않음.
- Windows CI는 각 테스트의 명시적 PASS marker + script/parse/compile error scan으로 판정해, Godot 4.7.2가 정상 종료 뒤 남길 수 있는 native exit-code 오탐을 제거.

## Tests / CI
GitHub Actions **Godot CI run #607 / 36088073563**:
- Linux validate: **PASS**
- Windows validate: **PASS**
- import / every-script parse: **PASS**
- main suite: **ASTRA TESTS OK · 61,813 checks**
- campaign: **ASTRA CAMPAIGN 080 TESTS OK · 219 checks**
- agency: **ASTRA AGENCY 082 TESTS OK · 66 checks**
- Stage 2~4 paired agency: ACTIVE/PASSIVE public facts **53/0**, meeting shifts **34/0**, vote-intention changes **46/0**
- UI smoke / retained story / character / visual suites: **PASS**
- Deep / pixel: **PASS**
- main scene boot: Linux/Windows **PASS**
- Windows release-candidate build: **PASS**

## Windows build
- ZIP: `ASTRA-0.8.2-windows.zip`
- size: **98,005,396 bytes**
- SHA256: `8172e2ee0e384e6d877ec5e5cfdfb34f198f04ef141abe2c524ff905a458644f`
- GitHub Actions RC artifact: `ASTRA-0.8.2-windows-rc` (artifact id 10845086117)
- exported game / packaging pipeline: **PASS**

## Balance / scope
0.8.2는 밸런스 확률을 다시 조정하는 버전이 아니다. 따라서 0.8.1의 40-game 결과를 현재 baseline으로 그대로 사용한다. 핵심 목적은 기존 player-agency 차이를 새 규칙으로 억지로 키우는 것이 아니라, **플레이어 행동이 실제 공개 정보·회의 판단·투표 의향을 바꾸는 경로가 살아 있는지 회귀로 고정하는 것**이다.

## Audit notes
- PR diff의 runtime 변경은 `scripts/core/game_session.gd`의 agency provenance/telemetry와 accusation basis metadata에 제한됨.
- passive route가 player-caused provenance를 만들지 못하도록 회귀로 고정.
- 기존의 사실상 항상 통과하던 agency 관측 조건을 제거하고, ACTIVE 경로가 public / meeting / vote 세 attribution path를 최소 한 번 실제 행사하도록 gate를 강화.
- UI smoke 종료 시 Godot 4.7.2 headless/dummy renderer가 texture/text RID cleanup 진단을 출력할 수 있으나, Linux/Windows authored assertions, main-scene boot, Windows export는 모두 통과함. 이는 현재 게임 런타임 실패로 판정하지 않으며 별도 engine-test teardown 진단으로 유지한다.

## Remaining human-only risks
자동화로 완료 판정하지 않는다.
- 실제 60분 플레이의 재미와 피로
- Stage 2~4의 높은 PASSIVE 승률이 체감상 “방이 알아서 푼다”로 느껴지는지
- 한국어 대사의 자연스러움과 반복 피로
- 인터루드 조작감
- finale 감정선과 세 ending tone의 차이
- player contact → 공개 → NPC 판단 변화가 실제 화면에서 충분히 읽히는지

---

# 0.8.1 CONTAINMENT TUNING — FINAL VALIDATION — 2026-09-25

기준 main: `8741194830bab29f600d1a379423cf34b2a5825a`  
검증 branch: `2a13ca20e3cad5c4a1f539783c97d76fa8688240` (PR #19, merge 전)  
VERSION / project.godot: **0.8.1**. Snapshot v4 유지.

## Functional
- Archive protocol: Stage 5 GUARDIAN, Stage 6 GUARDIAN/ANALYST, Stage 7+ GUARDIAN/ANALYST/EMPATH. AUDITOR는 player-facing 목록에서 제거하고 legacy 입력만 ANALYST로 정규화.
- Progression: attempt(`case_counts`)와 clear(`case_wins`) 분리. 실패는 다음 Stage / campaign completion / Deep을 열지 않음.
- Slot isolation: Archive replay와 campaign availability는 active slot의 voyage memory를 사용.
- Deep: 실제 campaign clears 기반. 기존의 legitimate completion flag는 보존.
- Retry/reload: retry는 새 seed, snapshot reload는 같은 seed/day/packet을 유지.
- ANALYST regression: bounded deterministic fixture에서 후보 2개 이상을 강제하고 compare verdict 및 당일 재사용 불가를 검사.
- Player agency: same-seed Stage 3에서 player contact가 private fact의 public-room 진입 여부를 실제로 바꾸는 회귀를 유지.

## Tests / CI
GitHub Actions **Godot CI run #599 / 36034419630**:
- Linux validate: **PASS**
- Windows validate: **PASS**
- import / every-script parse: **PASS**
- main suite: **ASTRA TESTS OK · 61,813 checks**
- UI smoke / Archive smoke: **PASS**
- campaign + agency: **PASS**
- Deep: **PASS**
- pixel: **PASS**
- retained story/character/visual suites: **PASS**
- Windows release-candidate build: **PASS**
- main scene boot: Linux/Windows **PASS**
- save snapshot/reload + legacy AUDITOR normalization: **PASS**

## Balance — 40 games / Stage
| Stage | SMART | RANDOM | PASSIVE |
|---|---:|---:|---:|
| CALIBRATION | 100% | 70% | 65% |
| DEAD_AIR | 95% | 82% | 87% |
| GLASS_GARDEN | 100% | 87% | 95% |
| ECHO_WARD | 95% | 95% | 97% |
| SILENT_ORBIT | 100% | 70% | 57% |
| RED_SHIFT | 90% | 57% | 55% |
| LAST_LIGHT | 92% | 40% | 40% |
| SECOND_WATCH | 87% | 55% | 65% |
| BORROWED_DAYS | 87% | 57% | 37% |
| BLIND_DECK | 92% | 70% | 65% |
| THREE_MINUTES_DARK | 92% | 77% | 52% |
| CONTINUITY | 80% | 65% | 50% |
| THRESHOLD | 92% | 55% | 55% |

TOTAL: SMART **92%** · RANDOM **67%** · PASSIVE **63%**. PART II SMART **90%** / PASSIVE **53%**.  
SMART public contribution **1.70/game** vs PASSIVE **0.66/game**, secrets+admissions **1.65/game**.

Stage 2~4 PASSIVE는 **87 / 95 / 97%**로 여전히 높다. 0.8.1은 untouched private record/witness/hearsay의 자동 공개를 낮추고 player-contact 공개를 강화했지만, PART I의 한 Null + 여러 투표 기회 구조 때문에 승률 자체는 여전히 관대하다. 이 수치를 숨기거나 목표 숫자에 맞추기 위해 NPC 판단을 무작위화하지 않았다. 실제 플레이에서는 정보 공개뿐 아니라 희생/속도/판단 변화 체감을 계속 사람 플레이로 확인해야 한다.

## Dialogue audit
우선 감사: `social_lines_080.gd`, `stage_story_080.gd`, `interludes_080.gd`, `dialogue_bank.gd`, `dialogue_variants.gd`, `story_content.gd`, `voyage_content.gd`, current meeting/vote/failure/finale paths.
- cliché 후보(“어쩌면 우리는…”, “한 가지는 확실해”, “이건 시작일 뿐이야” 등) 반복 검색: 대량 반복 없음.
- exact long-line duplicate 통계에서 의도적 shared player-choice / mirrored story source가 주된 중복임을 확인.
- pressured confession 3문장을 노아/소렌/마렌 voice에 맞게 분리.
- legacy unlock queue에서 현재 기능이 아닌 marks/private_talk/theory_report/night_tactics/hypothesis를 새 해금처럼 노출하지 않게 제거.
- protocol unlock 문구의 구형 “감사관” 설명 제거.
- dialogue consistency는 placeholder token, internal enum/key, roster/speaker, banmal voice를 자동 검사.
- 이번 pass의 직접 대사 변경: **3문장**. 대량 재작성은 하지 않음.

## Windows build
- ZIP: `ASTRA-0.8.1-windows.zip`
- size: **98,001,993 bytes**
- SHA256: `60e921f7417a47b355c209195befdfb344c768f198f7f0db8634ae6f9dd2260a`
- release-candidate artifact: **PASS**
- exported EXE headless boot: **PASS**
- GitHub Release / tag: 이 작업에서는 생성하지 않음.

## Remaining human-only risks
자동화로 완료 판정하지 않는다.
- 실제 60분 플레이의 재미와 피로
- Stage 2~4의 높은 PASSIVE 승률이 체감상 “방이 알아서 푼다”로 느껴지는지
- 한국어 대사의 자연스러움과 반복 피로
- 인터루드 조작감
- finale 감정선과 세 ending tone의 차이
- player contact → 공개 → NPC 판단 변화가 실제 화면에서 충분히 읽히는지

---

# 0.8.0 CONTAINMENT — 최종 QA (사회추리 재구성 · 최종 통합 · 캠페인 확장) — 2026-09-24

기준: 로컬 작업 트리(원격 저장소 없음). 시작 VERSION 0.7.4 → **0.8.0**. 저장 v12(메타) / 스냅샷 v4.
엔진 Godot 4.7.2 stable. 이 절은 0.8.0 세 번의 지시(코어 재구성 · 최종 통합 · 최종 재미/재플레이/캠페인 확장)를 모두 반영한 최종 상태다.

## 1. 자동 검증

| 스크립트 | 결과 |
|---|---|
| `run_tests.gd` | OK · ASTRA TESTS OK · 61750 checks |
| `ui_smoke.gd` | OK · ASTRA UI SMOKE OK |
| `story_070_consistency.gd` | OK · ASTRA STORY 070 CONSISTENCY TESTS OK · 278 checks |
| `act2_070_tests.gd` | OK · ASTRA ACT2 070 TESTS OK · 26 checks |
| `character_arc_070_tests.gd` | OK · ASTRA CHARACTER ARC 070 TESTS OK · 115 checks |
| `visual_story_071_tests.gd` | OK · ASTRA 0.7.1 VISUAL STORY TESTS OK · 48 checks |
| `visual_story_072_tests.gd` | OK · ASTRA 0.7.2 VISUAL STORY TESTS OK · 52 checks |
| `visual_story_073_tests.gd` | OK · ASTRA 0.7.3 HUMAN SIGNAL TESTS OK · 65 checks |
| `human_aftermath_062_tests.gd` | OK · ASTRA 0.6.2 HUMAN AFTERMATH TESTS OK · 150 checks |
| `codex_056_tests.gd` | OK · ASTRA 0.5.6 CODEX TESTS OK · 95 checks |
| `fault_lines_055_tests.gd` | OK · ASTRA 0.5.5 FAULT LINES TESTS OK · 7592 checks |
| `knowledge_propagation_tests.gd` | OK · ASTRA 0.5.3 KNOWLEDGE PROPAGATION TESTS OK · 12 checks |
| `storylet_scheduler_tests.gd` | OK · ASTRA 0.5.3 STORYLET SCHEDULER TESTS OK · 119 checks |
| `routine_model_tests.gd` | OK · ASTRA 0.5.4 ROUTINE MODEL TESTS OK · 17928 checks |
| `meaningful_choice_tests.gd` | OK · ASTRA 0.5.4 MEANINGFUL CHOICE TESTS OK · 2 checks |
| `curiosity_pin_tests.gd` | OK · ASTRA 0.5.4 CURIOSITY PIN TESTS OK · 9 checks |
| `walkthrough_080.gd` | OK · ASTRA WALKTHROUGH 080 OK · 807 lines |
| `campaign_080_tests.gd` | OK · ASTRA CAMPAIGN 080 TESTS OK · 217 checks |
| `deep_080_tests.gd` | OK · ASTRA DEEP 080 TESTS OK · 66 checks |
| `pixel_080_tests.gd` | OK · ASTRA PIXEL 080 TESTS OK · 803 checks |

- 봇 균형(`run_tests.gd --games=40`): TOTAL SMART 90% · RANDOM 65% · PASSIVE 64% · PART II SMART 87% / PASSIVE 55% (61,750 checks, TESTS OK)
- 기여도: SMART가 공개로 만든 사실 1.69개/판 vs PASSIVE 0.60개/판 · 비밀과 자백 1.63개/판
- 시각: `visual_080.gd`(1366·1920), `visual_interludes_080.gd`(인터루드 9개), `visual_final_080.gd`(최종 악장 · 크레딧 · Deep)로 캡처해 사람이 직접 검토.
- 읽는 대본: `walkthrough_080.gd` → `build/qa/walkthrough_080.txt`(형식이 덜 채워진 줄이 하나라도 있으면 실패).
- Windows 빌드 (`tools/build_windows.ps1`, 위 스위트 전체 포함): `build/ASTRA-0.8.0-windows.zip` 96,845,788 bytes, SHA256 `ef4925304aa663533a3ddc12c8ec7575c194da34d934924a9b6e344bc9d31bc4`. ZIP 안: `ASTRA/ASTRA.exe`(168,233,440) · `START_HERE.md` · `LICENSES.md`. 내보낸 exe 부팅: headless 10프레임 + 창 모드 240프레임(OpenGL Compatibility, Intel Iris Xe) 모두 오류 0.
- 동작 시각: `visual_motion_080.gd`, `visual_life_080.gd`(도트 캐릭터 동작 · 실제 방).

## 2. 밸런스와 플레이어 영향력 (§5-§7)

### 게이트를 어떻게 정했나
0.7.x의 “passive < 20%”는 기권하는 봇 기준이었다(0.8.0에는 기권이 없다). 새 규칙에서 PASSIVE는 “아무와도 대화하지 않고 방의 다수를 따라 투표하는 탐사요원”이다.
PART I은 Null 1명에 여러 번의 투표 기회가 있어 구조적으로 관대하다(튜토리얼 악장). 그래서 승률 격차만이 아니라 **희생자 수와 해결 속도**를 함께 본다.
정보를 숨겨서 격차를 만들지 않았다: 단서는 그대로 두고, 한 사람의 단서만으로는 결론이 나지 않게(증거 곡선), 같은 모양의 흔적을 무고한 사람도 남기게 했다.

### Stage별 (40판)
| Stage | SMART | RANDOM | PASSIVE |
|---|---|---|---|
| 1 CALIBRATION | 97% | 70% | 65% |
| 2 DEAD_AIR | 95% | 80% | 80% |
| 3 GLASS_GARDEN | 100% | 90% | 92% |
| 4 ECHO_WARD | 92% | 95% | 97% |
| 5 SILENT_ORBIT | 90% | 55% | 62% |
| 6 RED_SHIFT | 92% | 62% | 65% |
| 7 LAST_LIGHT | 80% | 35% | 40% |
| 8 SECOND_WATCH | 85% | 55% | 57% |
| 9 BORROWED_DAYS | 82% | 50% | 42% |
| 10 BLIND_DECK | 87% | 62% | 72% |
| 11 THREE_MINUTES_DARK | 95% | 67% | 55% |
| 12 CONTINUITY | 80% | 60% | 50% |
| 13 THRESHOLD | 92% | 62% | 55% |

- PART II 평균 격차 SMART − PASSIVE = **32%p**, SMART − RANDOM = 25%p. 목표(15–20%p 이상, RANDOM보다 위) 충족.
- PART I Stage 3–4는 승률로는 격차가 없다(Stage 4는 PASSIVE가 더 높다: Null 1명, 7명, 여러 번의 투표 — 방의 다수가 결국 맞힌다).
  이 구간의 플레이어 차이는 아래 “희생과 속도”로 드러난다. 정보를 숨겨서 승률을 억지로 벌리지 않았다.

### 희생과 속도 (24판)
`probe_lives_080.gd` · Stage당 24판 · 값은 판당 평균 (무고 격리 = 포드에 보낸 무고한 사람, 사망 = 밤에 잃은 승무원).

| Stage | SMART 승 · 무고 격리 · 사망 · 날 | PASSIVE 승 · 무고 격리 · 사망 · 날 |
|---|---|---|
| 1 CALIBRATION | 91% · 0.21 · 0.13 · 1.1 | 70% · 0.67 · 0.38 · 1.4 |
| 2 DEAD_AIR | 87% · 0.58 · 0.46 · 1.5 | 83% · 0.83 · 0.79 · 1.7 |
| 3 GLASS_GARDEN | 100% · 0.42 · 0.42 · 1.4 | 79% · 1.08 · 0.88 · 1.9 |
| 4 ECHO_WARD | 91% · 0.38 · 0.29 · 1.3 | 87% · 1.13 · 1.13 · 2.0 |
| 5 SILENT_ORBIT | 91% · 1.17 · 1.67 · 3.0 | 58% · 2.04 · 2.50 · 3.5 |
| 6 RED_SHIFT | 91% · 0.96 · 1.58 · 2.8 | 58% · 1.96 · 2.38 · 3.4 |
| 7 LAST_LIGHT | 100% · 1.13 · 1.75 · 3.1 | 58% · 2.00 · 2.50 · 3.5 |
| 8 SECOND_WATCH | 95% · 0.96 · 1.58 · 2.9 | 75% · 1.75 · 2.46 · 3.5 |
| 9 BORROWED_DAYS | 95% · 0.79 · 1.50 · 2.8 | 50% · 2.17 · 2.50 · 3.5 |
| 10 BLIND_DECK | 91% · 1.00 · 1.58 · 2.9 | 70% · 1.42 · 1.92 · 2.9 |
| 11 THREE_MINUTES_DARK | 95% · 0.88 · 1.46 · 2.8 | 75% · 1.63 · 2.21 · 3.2 |
| 12 CONTINUITY | 83% · 0.83 · 1.29 · 2.6 | 45% · 1.92 · 2.13 · 3.1 |
| 13 THRESHOLD | 83% · 1.33 · 1.83 · 3.1 | 70% · 1.63 · 2.17 · 3.2 |

- PART I에서도 SMART는 무고한 사람을 포드에 보내는 일이 **1/3–1/2**, 밤에 잃는 사람이 **1/3–1/2**, 끝나는 날이 0.3–0.7일 빠르다
  (Stage 4: 무고 격리 0.38 대 1.13, 사망 0.29 대 1.13). 승률이 비슷한 Stage에서도 “누가 살아서 끝났나”가 달라진다.

### 증거 곡선 (§3, §4) — `probe_packets_080.gd`, Stage별 150 시드
| 날 | 한 명으로 좁혀짐 | 두 명 | 세 명 |
|---|---|---|---|
| Day 1 | 24–41% (Stage 1은 57%) | 42–67% | 9–22% |
| Day 2 | 55–67% | 28–40% | 2–10% |
| Day 3 | 68–88% | 12–26% | 0–5% |
이전(수정 전): Day 1 56–100%, **Day 2 이후 100%** 한 명으로 좁혀짐 → “Day 2가 정답” 공식.
이름을 바로 대는 목격/기록은 Day 1 5–16%. 작은 방에서도 목격 특징(머리 길이 추가)과 기록 종류(선실 구역 추가)를 함께 골라 목표에 맞춘다.

### 플레이어 없이 방이 맞히는 이유 (`probe_agency_080.gd`)
수정 전 PASSIVE 승리의 주원인은 “이름을 바로 대는 조각을 가진 사람의 자기 표”였다(DEAD_AIR Day 2: 정직한 승무원 표의 100%가 Null). 수정 후 Day 2 적중률은 Stage 2~4에서 44–84%, PART II Day 1 20–45%.

## 3. 재플레이성 (§74) — `probe_replay_080.gd`, Stage당 25–30 시드 × 13 Stage
| 분포 | 표본 | 결과 |
|---|---|---|
| Null이 누구인가 | 660 | 준 15 · 다렌 14 · 미라 13 · 세나 12 · 노아 12 · 소렌 11 · 마렌 10 · 루칸 9% |
| Null 쌍(PART II) | 270 | 가장 잦은 쌍 6% (다렌+준), 나머지 4–5% — 고정 조합 없음 |
| Null 성향 | 660 | DEFLECTOR 34 · QUIET 29 · COUNTERATTACK 21 · ALLY 14% |
| 그날 첫 지목자 | 1021 | 세나 20 · 노아 18 · 준 14 · 다렌 12 · 루칸 9 · 미라 9 · 소렌 8 · 마렌 6% (성격대로 치우치되 한 사람이 독점하지 않음) |
| 첫 격리 | 390 | 준 20 · 다렌 14 · 노아 13 · 미라 12 · 소렌/루칸/세나 11 · 마렌 6% |
| 밤 희생 | 637 | 노아 17 · 다렌 14 · 세나 14 · 루칸 13 · 마렌 12 · 미라 10 · 준 8 · 소렌 5 · 탐사요원 1% |
| 목격 조각 보유 | 395 | 8명 모두 8–15% |
| 기록 조각 보유 | 385 | 노아 31 · 다렌 21 · 세나 20% (직무상 기록을 보는 사람 — 의도된 치우침) · 나머지 2–9% |
| 무해한 거짓말 | 255 | 8명 모두 8–18% |
| 회의 첫 논점 | 1086 | 사람·종류가 흩어짐(최대 12%): 기록, 의심, 누명, 무해한 비밀 등 |

`probe_replay_080.gd`, Stage당 30시드 × 13 Stage, 방의 다수를 따르는 탐사요원. Day 2에 방이 결정하는 판: 18%.

**메타 공식 점검 (§12)**
| 공식 | 결과 | 처리 |
|---|---|---|
| 동행을 부정당한 사람 = 무고 | Null 17% | Null의 “빌린 알리바이” 추가(한쪽만 동행 주장) — 수정 전 0% |
| 동행을 주장했는데 상대가 부정 = 무고 | Null 27% | 같은 수정 |
| 그날 첫 지목자 = Null | 33% | 수정 전 **62%**. Null은 공개 근거·압박 없이 첫 지목을 서두르지 않음, 누명 씌우기는 회의 첫 논점이 되기 어렵게 |
| 첫날 조용한 사람 = Null | 21% | 기준선(≈18%) |
| Day 1에 단서가 없는 사람 = Null | 22% (기준 16%) | 수정 전 33%. 누구나(Null 포함) 가질 수 있는 무해한 관찰(ROUTINE) 추가 |
| 밤 공격 = 최고 위협 | 70% | 항상 100%가 아님(성향·차폐막 예측·관계) |
| 반박된 목격 = Null | 해소 | 무고한 사람의 정직한 착각 목격(닮은 사람을 잘못 봄) 추가 |
| Night에 공격받은 사람 = 승무원 | 규칙상 참 | 가디언 정보의 보상으로 유지. 대신 다음 날 “차폐막이 막은 게 꼭 공격이었나”라는 의심이 나올 수 있음 |

**시드 정책 (§10, §28, §29)**: 새 캠페인·재구성 재시도·Stage 다시 = `AstraGameSession.fresh_seed(previous)`(직전 시드와 절대 같지 않음) + 최근 Null 반복 억제.
불러오기 = 같은 시드·같은 Day Packet·같은 Null(테스트: `campaign_080_tests.gd`). 30회 재시도에서 서로 다른 Null 조합 4가지 이상.

## 4. 이야기 (§75) — Stage별 정합성
`docs/STORY_LEDGER_080.md`(사실)와 `docs/CAMPAIGN_PACING_080.md`(리듬)가 기준이다. 모든 Stage가 **답 하나 + 다음 질문 하나**를 가진다.

| # | 지역 질문 | 밝혀지는 사실 | 큰 단서 | 스포트라이트 | 재동기화 설명 | 남은 모순 / 처리 |
|---|---|---|---|---|---|---|
| 1 | 누가 위치를 거짓말하나 | 실행자 서명은 처음부터 비어 있었다 | 노아의 날짜 어긋남 | 미라, 노아 | 결말 장면(첫 노출) | 없음 |
| 2 | 누가 누구를 감싸나 | 목적지 원본이 둘, 둘 다 진짜 | 목적지가 둘 | 세나 | 오프닝에서 짧게 | 인터루드가 답을 미리 말하지 않게 “진짜처럼 보인다”로 수정 |
| 3 | 들은 말과 본 말 | 세나의 근무 기록 ≠ 준의 기록 | 기록 이중성 | 준↔세나, 소렌 | 변주 문장 | 없음 |
| 4 | 시간인가 장소인가 | 신호 속 목소리는 진짜, 시간만 뒤틀림 | 7초 늦은 시계 | 소렌, 루칸 | 변주 | 없음 |
| 5 | 두 Null의 공조 | 도착 완료, 19년 전 | 19년 | 루칸, 다렌, 마렌 | PART II 전환 장면 | 없음 |
| 6 | 한 사람과 가까워지는 Null | 출항보다 오래된 시료 | 도착 이후 | 마렌 | 변주 | 인터루드의 확정 표현을 “태그가 맞다면”으로 완화 |
| 7 | 역공하는 Null | Null ≠ 큰 미스터리 | (중간점 1) | 다렌, 준 | 변주 | 없음 |
| 8 | 기록 과신 | 도착 후 40일 근무 | (중간점 2) 우리는 살았다 | 노아 | 변주 | 없음 |
| 9 | 몸의 습관 | 기록은 하나, 습관은 둘 | 감정 잔향 | 준↔세나 | 균열 실패 장면 시작 | 없음 |
| 10 | 없는 장소 | 지도에서 지운 구역 | 같은 갑판, 다른 문 | 루칸, 노아 | 변주 | 인터루드가 이전 장면을 봤다고 가정하지 않게 수정 |
| 11 | 보지 못한 곳 | 직접·기록·전언의 무게 | 세 경보 | 루칸/노아/소렌, 미라 | 변주 | 없음 |
| 12 | 평범함 속 거짓 | 하루의 모양은 같다 | 식사표의 내 칸 | 마렌, 미라 | 폭풍 전 저녁 | 없음 |
| 13 | 무엇을 보존하나 | 도착 후 살다가 다시 잠들었다 | 모두 잠든 뒤 누가 깨어 있었나 | 모두 | 최종 악장 | 남기는 질문은 1개로 제한 |

- 재동기화 문장은 Stage마다 달라진다(`RESYNC_LOST/ISOLATED/QUIET`). Stage 9부터 실패는 “균열” 장면.
- 감정 잔향: 다음 첫 아침에 최대 1회(PART II 첫 Stage는 확정), 역할·정답 없음(테스트).

## 5. 마찰 (§76)
- 새 프로필에서 첫 의미 있는 선택까지 **17클릭**(탐사요원 등록 포함), 첫 투표까지 **25클릭** (`ui_smoke.gd`).
- Stage당 클릭(`probe_clicks_080.gd`, 이야기 장면 포함): PART I 29–36 (이야기 12–15), PART II 59–69 (이야기 20–23, 평균 2.5–2.9일).
- 없앤 것: 회의·투표 시작 배너(첫 줄을 가렸음), 대화 카드와 중복되던 “새로 알게 된 것” 알림, 회의 머리글의 중복 분위기 문장, 둘째 날부터의 투표 규칙 설명, 결과 화면의 중복 “정체는 표시되지 않는다”, 격리 대사와 똑같던 “마지막 한마디”.
- 자동 전환: 아침→대화, 사망→결과(다음 날로 넘어가지 않음), 인터루드→대화.
- 한 화면 동시 선택지: 대화 질문 ≤3 + 회의 열기, 회의 개입 ≤3 + 지목, 투표는 후보 선택 → 확인(되돌릴 수 없는 결정이라 유지).
- 투표 공개: 첫 투표 0.7초 간격, 이후 0.4초, Space/Enter로 즉시 전체 공개.
- 노트 필수 여부: SMART 봇은 노트를 한 번도 열지 않고 90% 승리.
- 1366×768: 등록·인터루드·최종 화면·Deep 화면에서 겹침 없음. 알림은 대화가 아니라 상단 할 일 줄 위에 뜬다.

## 6. 시각
- 초상화 흰 테두리: 배경 제거 잔여 → 셰이더(알파 침식 + 밝은 가장자리만 감쇠 + 시트 구분선 제거). 8명 전원·주요 표정에서 밝은 머리(마렌·노아·다렌), 흰 옷, 눈 하이라이트가 지워지지 않는 것을 캡처로 확인.
- 도트 캐릭터: 변환 단계에서 정리(반투명 번짐 제거 → 프리멀티플라이드 축소 → 알파 경계 선명화 → 가장자리를 캐릭터 내부색 기반 윤곽선으로). 셰이더를 쓰지 않는다. 14장 모두 방향·크기·발 위치 일치(`pixel_080_tests.gd` 533항목).
- 도트 캐릭터 동작(사용자 요청 — 걷기만 있어 딱딱함): 그림을 새로 그리지 않고 걷기 프레임을 머리·상체 띠로 정수 픽셀만큼 움직여 숨쉬기·끄덕임·인사·갸웃·한숨·놀람 점프·기쁨·작업 자세(뒤·옆·읽기)·앉기(탁자가 다리를 가림)를 만들었다. 말풍선 ! ? … ♪, 땀방울. 방 안 사람들은 일하다가 탐사요원이 오면 돌아보고(처음 한 번 “!”), 떠나면 일로 돌아가며, 서성이고 두리번거린다. `visual_motion_080.gd`(동작 정지 화면 + 3배 확대)로 얼굴에 이음매가 없는지 확인: 목 띠는 캐릭터별로 턱 아래 두 줄(NECK_ROWS). `visual_life_080.gd`로 실제 방에서 알아챔·과제 반응·식사 장면 확인. `pixel_080_tests.gd` 803항목(제스처 수치·수명, 작업 복귀, 서성이기, 액션 시트, 대사 신호, 라운지 장면 끝까지).

## 7. 필요한 에셋 (있으면 좋아지는 것)
- 탐사요원 최종 걷기 시트·얼굴(`assets/player_src/README.md`), 승무원과 색이 겹치지 않게.
- (선택) 도트 **액션 시트**: 작업(뒷모습) · 말하기 · 앉기 · 반응 4행 × 3칸. 넣으면 해당 동작만 그림으로 바뀐다. 형식과 이미지 생성 요청문 예시는 `docs/PIXEL_ACTIONS_080.md`.
- 인터루드용 배경 소품이 지금은 도형으로 그려져 있다(작은 방 9개). 도트풍 타일/소품이 있으면 공간감이 크게 오른다.
- 최종 악장 전용 배경 1장(함교, 재수면 명령 화면), PART II 전환 영웅 이미지 1장.

## 8. 남은 재미 위험 (§79)
- PART I Stage 2–4는 여전히 관대하다(PASSIVE Stage 2–4: 80% / 92% / 97%, 40판). 플레이어의 차이는 희생자 수와 속도로 나타난다.
- 인터루드 9개의 “재미”는 봇으로 검증할 수 없다. 첫 프로토타입(Stage 4 신호 추적) 기준으로 나머지를 만들었지만, 실제 플레이로 느낌을 확인해야 한다.
- 플레이타임(9–12시간 목표)은 계측 장치만 넣었고(`final_report.stats.time_*`), 실제 측정은 사람 플레이가 필요하다.
- Deep 7깊이 이후 난이도 곡선은 시뮬레이션만 있고 사람 기준 조정은 아직.
- 도트 캐릭터와 탐사요원 외형은 임시 에셋이다.

---

# 0.7.4 PLAYBACK FULL COMPLETION QA — 2026-09-22

기준: `main @ 1099b3b3efe12e655dae595011176a54c6847520` (PR #17 merge 이후의 부분 구현 0.7.4)  
작업 브랜치: `feature/0.7.4-playback-completion`

## 저장소 재감사

- 시작 VERSION: **0.7.4** — 이번 completion에서도 **0.7.5로 올리지 않음**
- save schema: **v11 유지**
- 기존 authored voyage/reactive library: **622개**, 이번 신규/삭제 authored scene **0 / 0**
- art071 / art072 / art073: 각 **5개**, 총 15개 유지; 신규 visual asset **0**
- 기존 scheduler의 continuation / focus-family budget / speaker exposure / consequence priority 재사용
- 신규 manager **0**, 신규 persistent field **0**

## 실제 발견 및 수정

1. PR #17의 breathing-room guard는 의도대로 작지만 전용 회귀가 FOCUS probe 한 종류에 치우쳐 있어 MANDATORY/FOLLOWUP, player agency, consequence callback, chapter transition을 completion gate로 고정하지 못했다.
2. `AstraVoyageContent.RESET_FRAMING`이 ACT I의 LAST_LIGHT까지만 존재해, ACT II의 SECOND_WATCH~THRESHOLD 결과 화면이 전부 CALIBRATION의 “같은 목소리/반창고” 문구로 fallback했다.
3. Night/Briefing은 이미 즉시 consequence와 지속 social interpretation을 분리하는 구현이 있으므로 새 feedback system을 만들지 않고 회귀로 보호했다.

수정:
- ACT II 6개 chapter에 각 장의 기존 canon에서 파생한 고유 reset residue 추가
- `tests/playback_074_tests.gd`를 completion regression으로 확대
- MANDATORY/FOLLOWUP/FOCUS breathing-room, 직접 conversation/topic, micro-arc continuation와 delayed consequence, LAST_LIGHT→SECOND_WATCH→THRESHOLD, ACT II reset residue, Night/Briefing 분리, v11 legacy slot hydration, 8인 authored exposure, art071/072/073 15개, FIRST IMPRESSION 독립성, player-safe selector를 검증
- 기존 assertion / bot threshold 완화 없음

## 검증 상태

GitHub Actions의 Linux/Windows full gate는 completion PR에서 실제 실행값으로 갱신한다. 기존 CI는 `playback_074_tests.gd`를 양쪽 OS에서 직접 실행하므로 새 completion assertions도 동일 release gate에 포함된다. 실행 전 수치는 PASS로 기록하지 않는다.

# 0.7.2 ACT I VISUAL STORY PASS QA — 2026-09-22

기준: `main @ 9519464c8916a2f9def58a641c81ffcca30037b1` (ASTRA 0.7.1)  
작업 브랜치: `feature/0.7.2-act1-visual-pass`

## 구현 범위

- 신규 scene art: **5장** — CALIBRATION / ECHO_WARD / SILENT_ORBIT / RED_SHIFT / LAST_LIGHT
- 자산: `assets/art072/`, SVG 1280×720, baked text 없음
- 선택 판단: DEAD_AIR는 LAST_LIGHT와 병렬 기록 구도가 겹쳐 제외, 초반 기억점이 필요한 CALIBRATION 선택
- 표시: 기존 `AstraArt` + `AstraVoyageView` stage 재사용; 4개 resolution + CALIBRATION first_wake
- 기존 ACT II 0.7.1 이미지 5장 유지
- save schema: **v11 유지**, migration 없음
- 신규 시스템/manager: **0**
- player-facing `history` 잔존 표현 정리
- CI: 0.7.0 누락 직접 실행 3종 + 0.7.2 visual regression 추가

## 검증 상태

GitHub Actions 결과는 PR 실행 후 이 문서에 실제 run 결과로 갱신한다. assertion/threshold는 낮추지 않았다.

# 0.7.1 VISUAL STORY PASS QA — 2026-09-22

기준: `main @ 4e7099458e2e3d7db3722c15ddce3eac133ab94f` (ASTRA 0.7.0 SECOND WATCH)  
작업 브랜치: `feature/0.7.1-visual-pass`

## 구현 범위

- 신규 scene art: **5장** — SECOND_WATCH / BLIND_DECK / THREE_MINUTES_DARK / CONTINUITY / THRESHOLD
- 자산 형식/크기: SVG, **1280×720**, baked text 없음, 신규 캐릭터 얼굴 정의 없음
- hookup: 기존 `AstraArt` + `AstraVoyageView` stage 재사용
- 표시 시점: 선택된 5개 장의 `story_resolution_*` thread에 한정
- fallback: 미매핑/누락 자산은 기존 room art + portrait
- 콘텐츠: 선택된 5개 chapter situation/outro + resolution action/dialogue 편집
- canonical fact / handling choice / chapter order / progression: 변경 없음
- save schema: **v11 유지**, migration 없음
- 신규 시스템/manager: **0**

## 검증 결과

GitHub Actions PR run **35703454042** (PR #14) — Linux `validate` / Windows `windows-validate` **GREEN**, release-candidate job은 개발 PR 정책대로 **SKIPPED**.

- Linux/Windows Godot 4.7.2 import / script validation: **PASS**
- `--games=40`: **99,523 checks PASS**, smart **79%** / random **19%** / passive **0%** — 기존 gate 유지
- campaign: **202 checks PASS**
- story consistency: **419 checks PASS**
- voyage regression: **745 checks PASS**
- Linux / Windows full `ui_smoke.gd`: **PASS**
- 0.7.0 story consistency: **278 checks PASS**
- 0.7.0 ACT II regression: **26 checks PASS**
- **0.7.1 visual story regression: 49 checks PASS**
- content audit: **0 FAIL / 0 WARN**
- Linux / Windows main-scene boot: **PASS**
- save schema: **v11 유지**, migration 없음
- 신규 시스템/manager: **0**
- 정식 Windows packaging / tag / GitHub Release: **미실행** — 이번 요청은 0.7.1 소규모 코드/자산 패치 반영이며 기존 개발/릴리스 분리 정책 유지

기존 assertion/threshold는 낮추지 않았다. 신규 SVG 5장은 양쪽 OS import를 통과했고, 전체 UI smoke가 selected ACT II resolution까지 실제로 진행되어 이미지 삽입 뒤에도 대화 진행과 캠페인 흐름이 막히지 않음을 확인했다.

# 0.7.0 SECOND WATCH QA — 2026-09-22

로컬 검증만 수행 (GitHub Actions CI 미실행 — 이 리포지토리는 이번 작업 세션에서 zip 추출본으로 시작해 git 이력이 없었고, `git init`으로 새 baseline을 만들었다). 검증 환경: `C:\Users\user\Desktop\Codex\tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe` (Godot 4.7.2.stable.official.ed1daf0bf), Windows 11, 각 테스트를 단독 프로세스로 순차 실행(동시 실행 시 같은 `user://` 저장 경로를 두고 경합이 발생해 응답이 멈춘 것처럼 보이는 문제를 개발 중 직접 겪었다 — 상세는 아래 "개발 중 발견한 문제" 참고).

- Linux import: 미실행 (Windows 전용 환경)
- 전체 GDScript parse / import: **PASS** (`godot --headless --path . --import`, 매 변경 후 재실행)
- content_audit: **0 FAIL / 0 WARN**, authored scene **622개**, pairing **21개**
- story_consistency_tests: **419 checks PASS**
- campaign_tests: **202 checks PASS** (기존 106 → 캠페인 6→12개 확장에 맞춰 두 배)
- voyage_tests: **745 checks PASS**
- storylet_scheduler_tests: **119 checks PASS**
- human_trace_061_tests: **326 checks PASS**
- human_aftermath_062_tests: **150 checks PASS**
- mira_content_tests: **36 checks PASS** (Mira authored scene 100, 최대치 80~100 범위 내 유지)
- **신규** story_070_consistency: **278 checks PASS**
- **신규** act2_070_tests: **26 checks PASS**
- **신규** character_arc_070_tests: **115 checks PASS**
- **신규** act2_070_simulation (20 seed): **520 checks PASS**, dead-end **0**, THRESHOLD 필수 reveal 도달 **20/20**
- ui_smoke (전체 12 case, 양쪽 save slot, DEAD_AIR·SECOND_WATCH 1366×768/1920×1080 레이아웃 확인 포함): **PASS**
- deduction bot (`--games=40`, 전체 12 case × 3 protocol = 1440게임): smart **79%** / random **19%** / passive **0%**, **99,523 checks PASS**
- bot gate: smart-random **+60%p** (기준 +30%p 이상), passive **0%** (기준 <20%) — **PASS**, 0.6.2 기록(smart 79%/random 19%/passive 0%)과 정확히 동일해 회귀 없음
- save schema: **v11 유지**, migration 없음 (ACT는 derived value, 새 저장 필드 없음)
- authored voyage/reactive library: **622**, 신규 14 / 재작성 3(ECHO_WARD·SILENT_ORBIT·RED_SHIFT RESOLUTION_BEATS 확장, 라인 수만 증가) / 삭제 0
- 정식 Windows packaging / EXE boot: **미실행** (export template 설치가 이 세션 환경에 없음 — 아래 "남은 작업" 참고)
- v0.7.0 tag / GitHub Release / release asset: **DEFERRED** (사용자가 별도 요청하지 않음, 기존 정책 유지)

## 개발 중 발견한 문제

1. **ACT II fact-tag 버그(실제 콘텐츠 버그, 수정 완료).** `CHAPTERS[...]["fact"]`에 `duty_log` 같은 새 문자열을 쓰면, investigation point가 `AstraVoyageContent.ROOMS`의 고정 8개 공유 태그(power/signal/destination/security/archive/arrival/everyday/sample)만 갖고 있어 해당 fact를 절대 만들어낼 수 없고, 그 결과 `goal_done`이 영원히 true가 되지 않아 EXPLORE phase에서 캠페인이 멈췄다. 전체 캠페인 UI 구동 검증(`ui_smoke.gd`) 중 발견했다. 6일 모두 기존 태그로 재매핑하고, 재발 방지 회귀를 `story_070_consistency.gd`에 추가했다.
2. **테스트 하드코딩(실제 버그, 수정 완료).** `voyage_tests.gd`와 `campaign_tests.gd`가 캠페인 길이 6(+CALIBRATION=7)을 배열 리터럴/매직넘버로 가정하고 있어 12로 확장하자 out-of-bounds로 죽었다. `AstraCaseCatalog.CAMPAIGN.size()`에서 동적으로 계산하도록 고쳤다. `first_contact_058_tests.gd`는 자체 case 목록을 따로 갖고 있어 영향받지 않음을 확인했다.
3. **개발 환경 문제(코드 버그 아님).** 위 두 버그로 스크립트가 `_initialize()` 중간에 크래시하면 `quit()`을 호출하지 못해 Godot 프로세스가 종료되지 않고 대기 상태로 남았다. 여러 백그라운드 실행을 동시에 두면 같은 기본 `user://` 저장 경로를 두고 경합해 두 프로세스 모두 응답이 멈춘 것처럼 보였다. 모든 프로세스를 종료하고 테스트 전용 저장 파일을 정리한 뒤 단독·순차 실행으로 전환해 해결했다. 향후 회귀 실행은 동시 실행을 피하는 것을 권장한다.

## 남은 작업

- 정식 Windows export template이 이 세션 환경에 설치되어 있지 않아 `ASTRA.exe` 빌드/부팅 검증을 하지 못했다. `tools/build_windows.ps1` / `tools/fetch_template.py`로 이후 실행 가능하다.
- GitHub Actions CI(Linux/Windows validation, release-candidate)는 이 리포지토리에 git 원격이 없어 실행하지 못했다. 사용자가 원격을 연결하면 기존 `.github/workflows/godot-ci.yml` 그대로 사용 가능하다.
- `AGENTS.md`는 이미 0.5.5/save v9 기준으로 낡아 있었다(이번 작업 시작 전부터). 이번 세션에서 고치지 않았다 — 별도로 갱신이 필요하다.
- Soren(소렌)·Lucan(루칸)이 8명 중 가장 적은 authored scene(65/63)을 유지한다. `content_audit.gd`의 spread 기준은 통과하지만, 스펙이 명시적으로 우려한 "조용한 캐릭터가 묻히는" 위험이므로 다음 패스에서 우선 검토 대상이다.

# 0.6.2 HUMAN AFTERMATH QA — 2026-09-22

구현 branch: `dev/0.6.2-human-aftermath` / 검증 보완 branch: `fix/0.6.2-aftermath-validation`  
PR: #12 + #13  
최종 보완 검증 GitHub Actions: run `35679587205` — Linux/Windows **GREEN**

- Linux import / 전체 GDScript parse / main scene boot: **PASS**
- Windows validation / UI smoke / main scene boot: **PASS**
- Core model: **49,255 checks PASS**
- Campaign: **106 checks PASS**
- voyage regression: **656 checks PASS**
- story consistency: **419 checks PASS**
- FIRST CONTACT: **259 checks PASS**
- reset safety: **22 checks PASS**
- NPC vote regression: **19,086 checks PASS**
- HUMAN TRACE: **326 checks PASS**
- HUMAN AFTERMATH: **150 checks PASS**
- HUMAN AFTERMATH 500-loop simulation: **13 checks PASS**
- human-readable editorial report: **PASS**
- dedicated aftermath UI smoke 1366×768: **PASS**
- dedicated aftermath UI smoke 1920×1080: **PASS**
- aftermath visual capture artifact: **PASS**
- Content Audit: **0 FAIL / 0 WARN**
- deduction bot (--games=40): smart **79%** / random **19%** / passive **0%**
- bot gate: smart-random **+60%p**, passive < 20% — **PASS**
- save schema: **v11**, migration 없음
- authored voyage/reactive library: **608**, 신규 scene 0 / 삭제 scene 0
- 정식 Windows packaging: **DEFERRED**
- v0.6.2 tag / GitHub Release / release asset: **DEFERRED**

500-loop HUMAN AFTERMATH 측정:
- meaningful choice: **500**
- immediate reaction exposure: **500**
- next-day consequence exposure: **242**
- next-loop callback exposure: **166**
- duplicate feedback exposure: **0**
- zero-aftermath meaningful choice: **0**
- ordinary optional starvation: **0**
- unrelated new-thread count: **0**
- visible continuation: **166**
- unreachable callback IDs: **0**
- repeat-resolution compression: **5/6 chapter probes**
- immediate reaction speaker distribution: noa 138 / sena 56 / vale 56 / eli 56 / lyra 56 / dax 83 / rho 28 / mira 27
- callback speaker distribution: vale 28 / noa 82 / eli 28 / sena 28

실제 UI 검증 중 RED_SHIFT next-loop residue의 행동 주체가 노아인데 base resolution speaker가 남아 초상/화자가 어긋날 수 있는 경로를 발견했다. callback별 visible speaker를 authored residue 행동과 일치시키도록 수정하고 1366×768/1920×1080 회귀로 고정했다. 테스트 기준/기존 threshold는 낮추지 않았다.

# QA REPORT — ASTRA 0.6.1 HUMAN TRACE

검증 환경: Godot 4.7.2 stable · GitHub Actions Linux/Windows validation  
작업 브랜치: `dev/0.6.1-human-trace`

## 개발 업데이트 정책

Windows packaging / tag / GitHub Release는 최종 배포 시점까지 의도적으로 보류한다. latest formal GitHub Release가 v0.5.7인 것은 개발 실패가 아니다. 일반 PR/main Godot CI와 Windows validation은 계속 gate로 사용한다.

## 구현 범위

- DEAD_AIR~LAST_LIGHT: canonical fact 이후 authored handling choice 연결
- 기존 voyage choice / DialogueMemory / memory tag / KnowledgeModel / ownership 재사용
- 선택 뒤 최대 1회 HUMAN reaction 후 story hook 복귀
- 다음 loop residue callback 및 repeat-resolution compression
- release.yml: main push packaging 제거, v* tag + workflow_dispatch 유지
- save schema: **v11 유지**, migration 없음

## 검증 결과

검증 commit: `51e2d82c4e426ab6b165b25ce244d468f3caba88`  
GitHub Actions: run `35673297533` (#536)
후속 opener 정리 검증: run `35675120500` (#541), commit `b67467a0ae95ffc168b1175451c2cd465a97fe5c` — Linux/Windows **GREEN**

- Linux import / 전체 GDScript parse: **PASS**
- Linux validate: **PASS**
- Windows validate / UI smoke / main-scene boot: **PASS**
- HUMAN TRACE: **326 checks PASS**
- 전체 core model: **49,255 checks PASS**
- campaign: **106 checks PASS**
- voyage regression: **656 checks PASS**
- story consistency: **419 checks PASS**
- FIRST CONTACT: **259 checks PASS**
- reset safety: **22 checks PASS**
- NPC vote regression: **19,086 checks PASS**
- `--games=40`: smart **79%** / random **19%** / passive **0%**
- deduction gate: smart - random **60%p** / passive < 20% — **PASS**
- CLEAR SIGNAL: **50 checks PASS** + 500-loop simulation **10 checks PASS**
- authored voyage/reactive library: **608**
- content audit: **0 FAIL / 0 WARN**
- repeated opener 5+: **없음**
- save schema: **v11 유지**, migration 없음
- dev branch `release-candidate-windows`: **SKIPPED (expected)**

기존 assertion/threshold는 완화하지 않았다. HUMAN TRACE 전용 회귀에는 canonical resolution fact 소유권, incidental `last_fact` 비공유, `information_sources` 문자열 schema 유지, speaker/public share 구분, mandatory reaction → story hook 우선순위, immediate consequence 보존을 포함한다.

Windows packaging: **NOT RUN — intentionally deferred**  
Git tag: **NOT CREATED — intentionally deferred**  
GitHub Release: **NOT CREATED — intentionally deferred**

---

# QA REPORT — ASTRA 0.6.0 FIRST CONTACT / STORY LOOP

검증 환경: Godot 4.7.2 stable · Linux + Windows x86_64  
작업 브랜치: `story-framing-20260922`  
release-recovery 검증 GitHub Actions: run **#518**  
검증 commit: `2373d96e0c58f88e0c7e7a8f8c6a36cb54ed9075`

## 구현 검증 결과

- Linux import / 전체 GDScript parse: **PASS**
- Linux validation: **PASS**
- Windows import / validation: **PASS**
- Windows UI smoke / main-scene boot: **PASS**
- voyage regression: **649 checks PASS**
- story consistency: **407 checks PASS**
- FIRST CONTACT: **259 checks PASS**
- reset safety: **22 checks PASS**
- NPC vote regression: **19,086 checks PASS**
- NPC ballot simulation: total **4,200** / abstain **0** / invalid **0** / self **0** / empty-reason **0**
- `--games=40` TOTAL: smart **79%** / random **19%** / passive **0%**
- deduction release gate: smart - random **60%p** / passive < 20% — **PASS**
- 0.5.4 save compatibility: **10 checks PASS**
- authored voyage/reactive scene: **608**
- content audit: **0 FAIL / 1 WARN**
- WARN: opener repeated 5+ — 같은(6), 자기(5), 당신이(6), 의료(5)

## CI #516 회귀 원인과 복구

1. **exploration choice enables actual night backup**  
   recorder runtime 연결 자체는 유지되어 있었습니다. `voyage_use_recorder()` → `voyage_backup` → 정상 exploration 완료 → `finish_voyage()` → `mission_backup` 경로입니다. 실패 원인은 0.6 contact-flow에서 `voyage_ask_goal()`이 더 이상 chapter fact를 지급하지 않고 안내만 하도록 바뀌었는데 voyage test가 과거의 자동 goal-completion 순서를 사용한 것입니다. 테스트를 실제 ECHO_WARD `signal` 조사 지점 검사로 바꿔 런타임 순서를 검증했습니다.

2. **100 seed scene variety**  
   DEAD_AIR의 첫 각성자가 Mira에서 Sena로 바뀌었는데 테스트는 Mira를 만나기 전에 `voyage_talk("mira")`를 직접 호출했습니다. 호출은 정상적으로 거부되어 빈 scene ID 하나만 수집됐습니다. 실제 플레이와 동일하게 Mira visit → awakening 종료 → ordinary talk 순서로 수정했고 기존 최소 3개 scene ID 기준은 유지했습니다.

## FIRST CONTACT / story 회귀

CALIBRATION 4인, 직접 조사 필수, first_panel 전용 choice routing, 순차 합류, ballot 상태, story resolution/hook, LAST_LIGHT canon, Player != Null 조건을 전용 gate에서 통과했습니다. assertion/threshold 삭제나 완화는 없습니다.

## Save compatibility

snapshot 지원 버전과 기존 hydrate 경로를 유지했고 destructive migration을 추가하지 않았습니다. 기존 0.5.4 compatibility fixture **10 checks PASS**입니다.

## 남은 release 단계

run #518은 PR 검증 GREEN입니다. main 병합 후 main CI, Windows 정식 build, EXE boot, ZIP/SHA256, tag `v0.6.0`, GitHub Release와 asset 재다운로드 검증 값을 이 섹션에 최종 기록해야 합니다.

---

# QA REPORT — ASTRA 0.5.7 CLEAR SIGNAL

검증 환경: Godot 4.7.2 stable · Linux + Windows x86_64  
작업 브랜치: `release/0.5.7`  
구현 검증 기준 commit: `dc3755eeac2b3420418daf1acac4d777cd8df05c`  
구현 검증 GitHub Actions: run `35572924051`

## 구현 검증 결과

- Linux import / 전체 GDScript parse: **PASS**
- Linux validation: **PASS**
- Windows import / validation: **PASS**
- Windows release-candidate build + exported EXE boot: **PASS**
- 전체 core model: **45,301 checks PASS**
- --games=40 TOTAL: smart **68%** / random **0%** / passive **0%**
- 0.5.6 Codex regression: **95 checks PASS**
- 0.5.6 ECHOES regression: **33 checks PASS**
- CLEAR SIGNAL invariant: **47 checks PASS**
- CLEAR SIGNAL runtime exposure: **10 checks PASS**
- save schema: **10**
- authored voyage/reactive scene: **608** (신규 **0**)

## CLEAR SIGNAL 500-loop

- optional authored scene: 평균 **4.15** / P95 **6** / 최대 **7**
- high-salience distinct family: 평균 **2.22** / P95 **3** / 최대 **4**
- unrelated new-thread: 평균 **2.22** / P95 **3** / 최대 **4**
- 4+ unrelated loop: **11 / 500**
- visible continuation: **10**
- zero-meaningful: **0** / max consecutive **0**
- visible signatures: **500 / 500**
- autonomous: 평균 **0.50** / 최대 **2** / unique **23**
- 0.5.3 authored coverage: **59.3%**
- rare immediate repeat: **0**
- Mira optional exposure: 평균 **0.62** / P95 **1** / 최대 **4**

프로필별 distinct family 평균/P95는 EXPLORER 2.13/3, LOYALIST 1.95/3, INVESTIGATOR 2.40/3, MINIMAL 2.04/3, SOCIAL 2.56/4다.

## 회귀와 content audit

기존 0.5.1~0.5.6 회귀 threshold를 낮추지 않았다. Mandatory/progression, 실제 FOLLOWUP/consequence, current-loop continuation, explicit topic, direct pinned question은 새-thread budget에서 보호된다. selector input에는 hidden Null, hidden motive, raw relationship float를 사용하지 않는다.

608개 library 크기 자체의 non-fatal warning은 CLEAR SIGNAL 500-loop runtime gate로 대체했다. opener 반복 경고는 단어 수만 출력하지 않고 해당 scene ID / speaker / action preview를 함께 출력한다.

## 공식 v0.5.7 Release 완료

- VERSION / project.godot: **0.5.7 / ASTRA 0.5.7 — CLEAR SIGNAL**
- annotated tag: `v0.5.7` → `e4b20a77e7295ff4afa4c4ed086f738272d9409e`
- main Godot CI: run `35575857582` — **completed / success**
- tag-source Windows build: run `35575857561` — **completed / success**
- source workflow artifact: `10627638550` (`ASTRA-0.5.7-windows`)
- GitHub Release: `v0.5.7` / ID `392806018` / **ASTRA 0.5.7 — CLEAR SIGNAL**
- published_at: `2026-09-21T08:46:43Z`
- Windows ZIP: `ASTRA-0.5.7-windows.zip`
- 파일 크기: **92,844,194 bytes**
- 공식 Release SHA-256: `5ea10cb171ce3d42e66da54c3c14d2adff6f9648a3d86e8166146c016a0846ec`
- `.sha256` 파일과 실제 ZIP hash: **일치**
- exported `ASTRA.exe` boot: **PASS** (run `35575857561`의 `build_windows.ps1` gate)
- published Release asset 재다운로드/구조/SHA 재검증: run `35579855349` — **PASS**

아래의 `35573583450` / `a9d1...` 값은 0.5.7 VERSION 승격 직후의 사전 RC 기록으로 보존한다. 이후 tag provenance를 직접 가진 main run `35575857561`은 같은 크기의 ZIP을 만들었지만 Godot export의 생성 cache/hash 영역과 archive metadata 때문에 byte-level SHA가 달라졌고, 공식 Release에는 tag commit `e4b20a77...`에서 직접 검증된 artifact `10627638550`을 사용했다. `dc4292...`에서 `e4b20...` 사이 변경 파일은 release workflow와 README / CHANGELOG / QA / RELEASE_NOTES뿐이며 gameplay 파일 변경은 없다.

## 0.5.7 사전 RC 기록

VERSION / project.godot을 0.5.7로 맞춘 최종 commit `dc4292bcd53c64fa2128593a6e35c788f2c8f7c7`, GitHub Actions run `35573583450`에서 Linux validation / Windows validation / Windows release-candidate가 모두 **PASS**했다.

- Windows ZIP: `ASTRA-0.5.7-windows.zip`
- 파일 크기: **92,844,194 bytes**
- SHA-256: `a9d1bdb0959c9d2dd3a51953daed48e8d146a7e33d17a1de862e1579d0a2f48b`
- exported `ASTRA.exe` boot: **PASS**

---

# QA REPORT — ASTRA 0.5.6 ECHOES

검증 환경: Godot 4.7.2 stable · Linux + Windows x86_64  
작업 브랜치: release/0.5.6  
구현 검증 기준 commit: 990ae1809d856e6f344ce9e1b981f5cfccae74e9  
GitHub Actions: run 35561855287

## 구현 검증 결과

- Linux import: **PASS**
- 전체 GDScript parse: **PASS**
- Windows import: **PASS**
- Linux validation: **PASS**
- Windows validation: **PASS**
- 0.5.6 release-candidate pre-build gate: **PASS**
- Codex: **95 checks PASS**
- ECHOES: **33 checks PASS**
- 전체 core model: **45,301 checks PASS**
- --games=40 TOTAL: smart **68%** / random **0%** / passive **0%**
- UI smoke: Linux/Windows **PASS**
- main scene boot: Linux/Windows **PASS**
- save schema: **10**
- v9 → v10 / legacy fixtures: Codex test에서 **PASS**
- authored voyage/reactive scene: **608**
- character scene: Mira 98 / Jun 81 / Daren 74 / Noa 79 / Sena 71 / Soren 64 / Lucan 62 / Maren 79
- Codex entries: TOTAL 32 / STABLE 14 / OBSERVED 10 / ECHO 8
- 신규 authored voyage scene: **0**

## 회귀와 편집 경고

기존 0.5.1~0.5.5 회귀, 1,000 conversation / 1,000 meeting / 500-loop Living Crew 계열 simulation, story continuity, first-play regression, content audit를 기존 threshold 그대로 통과했다.

현재 자동 리포트의 실제 non-fatal content WARN은 2개다.
- opener 반복: 같은(6), 자기(5), 당신이(6), 의료(5)
- 전체 authored scene 608개이므로 one-run exposure가 과해지지 않는지 계속 확인

Meaningful Choice audit의 warning count는 **0**이다. 실제 FAIL은 **0**이다.

## 버전/빌드 상태

위 run의 Windows RC build 자체는 성공했지만 검증 당시 repository VERSION이 아직 0.5.5였으므로 산출물은 **0.5.6 정식 artifact로 인정하지 않는다**.

VERSION / project.godot를 0.5.6으로 맞춘 최종 CI에서 Windows export, exported ASTRA.exe boot, ASTRA-0.5.6-windows.zip, SHA256을 다시 생성한 뒤 이 섹션을 실제 값으로 갱신한다.

---

# QA REPORT — ASTRA 0.5.5 FAULT LINES

검증 환경: Godot 4.7.2 stable · Linux + Windows x86_64  
작업 브랜치: `release/0.5.5`  
기준 commit: `44567f7fc9fe1aa413b81f15e68eacdd97b7f6d0` (ASTRA 0.5.4 AFTERMATH)

## 0.5.5 콘텐츠 / 시스템 기준

- 기존 authored voyage/reactive scene: **537**
- 0.5.5 신규 authored/reactive scene: **71**
- 전체 library: **608**
- 신규 scene 분배: 미라 10 / 준 9 / 다렌 8 / 노아 9 / 세나 8 / 소렌 9 / 루칸 9 / 마렌 9
- Personal Motive vocabulary: **11종**
- 한 loop motive NPC: **1~3명 / 최대 3**
- Dynamic Ship Incident: **8종**
- Incident: 한 loop 최대 1, CALIBRATION/DEAD AIR/GLASS GARDEN 0
- Cooperative Investigation: core fact 보존 + 인물별 secondary observation
- Delegation: SILENT ORBIT 이후 optional 조사 1회
- Foreknowledge: loop > 0 + 실제 과거 동일 incident 경험 필요, 사용 최대 2
- information source: DIRECT / RECORD / TESTIMONY / RUMOR
- familiar scene compression: seen >= 2 + safe metadata 조건, 전체 장면 다시 보기 가능
- post-arrival canon: 후보 4개, campaign visible 최대 2

## 0.5.5 자동 검증 게이트

`fault_lines_055_tests.gd`:
- 1,000 seed motive assignment / Null 독립성
- inactive / incompatible motive 금지
- motive multi-source progress
- incident chapter gate / deterministic selection / valid outcome
- foreknowledge loop/unseen/cap invariant
- source label
- repeat compression safety
- 71 authored scene ID / first-30-min protection
- specialist observation differentiation
- Mira expansion cap / Soren·Lucan depth

`fault_lines_055_simulation.gd`:
- 500-loop motive coverage / max / innocent suspicious behavior
- 1,000 incident selection + resolution coverage

`editorial_055_report.gd`:
- motive / cooperative / foreknowledge / canon / delegation human-readable sample

기존 0.5.1~0.5.4 regression, 1,000 conversation, 1,000 meeting, 500-loop replay, content audit, UI smoke, Linux/Windows import/parse, Windows export, exported ASTRA.exe boot, ZIP/SHA-256 gate를 그대로 유지한다.

> 이 문서의 “통과” 상태는 GitHub Actions의 동일 release HEAD가 green인 경우에만 정식 release 근거로 사용한다.

---

# QA REPORT — ASTRA 0.5.4 AFTERMATH

검증 환경: Godot 4.7.2 stable · Linux + Windows x86_64
작업 브랜치: release/0.5.4
기준: ASTRA 0.5.3 HEARTBEAT / 71f3c4f16ed41ca5564ad1b83e698fa9ac809f59

## 콘텐츠 수치

총 voyage/reactive authored scene: **537**

| 인물 | scene |
|---|---:|
| 미라 | **88** |
| 준 | 72 |
| 다렌 | 66 |
| 노아 | 70 |
| 세나 | 63 |
| 소렌 | 55 |
| 루칸 | 53 |
| 마렌 | 70 |

0.5.4 신규 scene: **64** (Mira 8 / Jun 7 / Daren 7 / Noa 7 / Sena 7 / Soren 10 / Lucan 10 / Maren 8)
Private event: **47**
Autonomous crew beat: **27**
pair-tag scene: **69**
trio scene: **11**

## Routine / Micro-Arc / Consequence

- 정상 activity: **36**
- authored deviation situation: **27**
- deviation reason: **10**
- Routine 1,000 simulated days: **17,916 checks**, sampled deviations **1,296**, max visible deviation **3**
- 대표 micro-arc: **8**, 각 4 beat
- authored consequence event: **23** — IMMEDIATE 4 / DELAYED 8 / NEXT_DAY 7 / NEXT_LOOP 4
- queue max: 12 + timing별 expiry
- NEXT_LOOP: consequence_carry로 voyage memory에 전달

## Decision / Knowledge

- non-abstain vote human-readable reason invariant 유지
- private clue를 모르는 NPC가 vote source로 사용하지 않음
- vote change는 strongest reason 기반으로 new_evidence / relationship_change / memory_change / uncertainty 분류
- 개표 UI에 이전 표 → 현재 표 + 이유 표시
- opinion trace에 known facts + qualitative relationship context 기록
- NPC→NPC knowledge propagation은 실제 share 경로가 있을 때만 발생

## Curiosity / Save

- pinned question 최대 1
- 관련 optional content weight만 소폭 증가
- 0.5.3 저장에 없는 routine/micro-arc/consequence/pinned-question/opinion 필드는 optional/default hydrate
- 기존 저장 강제 reset 없음

## Release gate

동일 HEAD에서 import+parse, 기존 전체 회귀, 1366×768/1920×1080, 0.5.1 stabilization, 0.5.2 Living Crew 규모 simulation, 0.5.3 HEARTBEAT 회귀, 0.5.4 전용 tests, AFTERMATH 500-loop, content audit, human-readable editorial report, Windows export, exported ASTRA.exe boot, ZIP+SHA-256이 모두 성공한 뒤 main으로 승격한다.

배포 파일: ASTRA-0.5.4-windows.zip / ASTRA-0.5.4-windows.zip.sha256

## 알려진 실제 한계

0.5.3의 action-prose opener WARN은 0.5.4 편집 패스에서 정리했다. 전체 537 scene의 모든 조합을 사람이 직접 플레이한 것은 아니므로 human-readable sample report와 simulation을 계속 보조 검증으로 유지한다.

---

## Historical QA — 0.5.3

검증 환경: Godot 4.7.2 stable · Linux + Windows x86_64  
작업 브랜치: `release/0.5.3`  
기준 브랜치: `release/0.5.2 @ 8f383a2855501a8ab159b0d90805af24ddeec36a`

0.5.3은 0.5.2의 Living Crew / Knowledge / Decision 기반을 유지하면서 Mira Emotional Anchor, Living Dialogue, autonomous crew beat, knowledge propagation, storylet pity와 player-visible replay QA를 추가했다.

## 자동 검증 상태

| 검사 | 결과 |
|---|---|
| 프로젝트 import + 전 GDScript parse | OK |
| 규칙·사건 생성·밸런스 | OK |
| campaign / mission / save compatibility | OK |
| UI smoke | OK |
| 1366×768 layout regression | OK |
| 1920×1080 layout regression | OK |
| 0.5.1 stabilization regression | OK |
| 0.5.2 Living Crew invariants | OK |
| 1,000 conversation simulation | OK |
| 1,000 meeting simulation | OK |
| 0.5.2 structural 500-loop diversity | OK |
| Mira content / tone / Null / isolation regression | **36 checks OK** |
| Storylet scheduler / pity / dialogue coherence | **119 checks OK** |
| Autonomous crew invariant | **260 checks OK** |
| Knowledge propagation | **12 checks OK** |
| Relationship / promise / pair callback | **10 checks OK** |
| 0.5.3 player-visible 500-loop simulation | **7 gates OK** |
| Story consistency / first-play regression | OK |
| Content audit | **0 FAIL / 1 WARN** |
| Windows Godot import | OK |
| Windows model tests | OK |
| Windows UI smoke | OK |
| Windows main-scene boot | OK |
| Windows release-candidate export | OK |
| exported `ASTRA.exe` boot | OK |

## Authored content

총 voyage/reactive authored scene: **473**

| 인물 | scene |
|---|---:|
| 미라 | **80** |
| 준 | 65 |
| 다렌 | 59 |
| 노아 | 63 |
| 세나 | 56 |
| 소렌 | 45 |
| 루칸 | 43 |
| 마렌 | 62 |

0.5.3에서 추가한 authored scene: **81**
- Mira pack: 27
- 다른 7인 callback pack: 28
- pair/trio social scene: 26

Private event:
- 미라: **13**
- 준: 5
- 다렌: 5
- 노아: 6
- 세나: 5
- 소렌: 4
- 루칸: 4
- 마렌: 5
- 총: **47**

Pair / trio:
- pair scene: **65**
- distinct valid unordered pair: **16**
- trio scene: **11**
- missing target / self-pair: **0** — content audit에서 FAIL 처리

Autonomous crew beat: **27**

## Mira Emotional Anchor QA

Mira authored speaker scene: **80**

현재 audit:
- agency metadata scene: 4
- player-specific scene: 20 / 80
- private event: 13
- CARE / DAILY / MEDICAL / PLAYER / RELATIONSHIP / ECHO / CONFLICT: 모두 존재
- WARM / PROFESSIONAL / STRAINED 동일상황 response: 서로 다른 문장 확인
- Mira Null seed sweep: Null 가능 확인
- Mira isolated/offline: 이후 Living Crew scene eligibility 차단 확인
- CALIBRATION 0.5.3 신규 storylet: 0
- 중후반 ordinary optional Mira exposure cap: 4

Phrase audit:
- “괜찮아요”: 1
- “잠깐”: 7
- “무리하지”: 0
- “확인할게”: 2
- “잃고 싶지”: 0
- “사랑”: 0

강제 romance confession / 항상 플레이어 편 / Null 면역 / 격리 면역은 추가하지 않았다.

## 500-loop player-visible replay simulation

최신 코드 검증 기준:

- loops: **500**
- player-visible signatures: **500**
- Mira optional exposure average: **2.50**
- Mira optional exposure max: **4**
- autonomous event unique coverage: **27 / 27**
- relationship pair coverage: **16**
- 0.5.3 authored scene coverage: **67.9%**
- rare event immediate repeat: **0**

이 signature는 seed 자체가 아니라 social theme + visible loop hook + 실제 노출된 0.5.3 scene + rare event를 기반으로 한다.

## Conversation / Meeting

0.5.2에서 도입한 규모 검증을 그대로 유지한다.

Conversation simulation:
- samples: 1,000
- topic mismatch: 0
- empty response: 0

Meeting simulation:
- meetings: 1,000
- bad reply: 0
- inactive speaker: 0

Meeting thread는 FACT_THREAD / RELATION_THREAD / DECISION_THREAD를 사용한다. 0.5.3 multi-line storylet은 line relation metadata를 별도로 audit한다.

## Knowledge invariant

0.5.3 전용 propagation test가 다음 경로를 검증한다.

1. player가 fact 발견
2. player → Noa 공유
3. Soren은 아직 모름
4. Noa → Soren 명시 공유
5. Lucan은 아직 모름
6. Soren → Lucan 명시 공유
7. public 이후 active roster가 앎

각 단계의 provenance가 남는다. private fact가 한 tick에 전원에게 퍼지는 diffusion은 없다.

Autonomous NPC share도 source가 실제로 아는 fact만 전달할 수 있고 DecisionTrace에 share 이유/source fact를 남긴다.

## Relationship / callback

검증 대상:
- player behavioral profile
- Mira privacy memory
- promise memory
- broken promise tag
- player accused/defended Mira
- NPC→NPC public defense memory
- pair callback eligibility

관계 UI는 숫자를 직접 노출하지 않는다.

## Content audit

최신 결과: **0 FAIL / 1 WARN**

남은 WARN:
- 행동문 첫 의미 단어 반복: `당신이` 16, `다렌의` 7, `처음` 5, `의료실` 6

이는 기능 오류나 template duplication FAIL은 아니지만 장기적으로 action prose의 문장 시작 리듬을 더 분산할 수 있다는 실제 품질 경고다.

## 첫 30분

회귀 금지:
- CALIBRATION 필수 흐름 유지
- CALIBRATION 0.5.3 신규 storylet 0
- DEAD AIR autonomous beat 0
- GLASS GARDEN autonomous beat 최대 1
- 회의/투표/밤의 단계적 해금 유지
- 금색 CTA와 contextual help 유지

Mira 콘텐츠 총량 증가는 첫판 필수 텍스트 증가로 연결하지 않았다.

## 저장 호환

기존 snapshot/save 필드와 내부 캐릭터 ID를 유지한다.

0.5.3 신규 상태:
- storylet_pity
- memory_tags
- promise_history
- autonomous_recent
- visible_signatures
- evidence_ownership 확장
- dialogue memory 확장

모두 선택적 nested field이며 오래된 저장에 없을 경우 기본값을 사용한다. 기존 save/campaign compatibility suite는 유지하고 통과한다.

## Windows release gate

`tools/build_windows.ps1`은 다음 순서를 완료해야 성공한다.

1. import
2. 전체 규칙/캠페인/UI/사회추리/반복 플레이 테스트
3. 0.5.1 stabilization
4. 0.5.2 Living Crew + 규모 simulation
5. 0.5.3 HEARTBEAT 전용 tests + 500-loop
6. story consistency
7. content audit
8. Windows export
9. `ASTRA.exe` 존재 확인
10. exported EXE headless boot
11. ZIP
12. SHA-256

최종 `VERSION=0.5.3` 승격 후 Linux validate, Windows validate, Windows release-candidate 세 job을 다시 실행하며 모두 성공해야 release branch를 main으로 승격한다.

배포 파일:
- inner package: `ASTRA-0.5.3-windows.zip`
- accompanying checksum: `ASTRA-0.5.3-windows.zip.sha256`
- exported `ASTRA.exe` headless boot: release gate에서 반드시 **OK**
- GitHub Actions RC artifact: `ASTRA-0.5.3-windows-rc`

ZIP은 패키징 시각 등 archive metadata 때문에 동일 소스의 재빌드에서도 byte-level SHA-256이 달라질 수 있다. 따라서 특정 빌드의 크기와 SHA-256을 이 소스 문서에 고정하지 않고, 실제 GitHub Release에 함께 첨부되는 `.sha256` 파일을 해당 artifact의 무결성 기준으로 사용한다. GitHub Actions가 업로드를 위해 다시 감싼 artifact ZIP의 digest 역시 배포용 inner package SHA-256과는 별개다.

## 남은 실제 문제

1. action prose opener 반복 WARN 1건.
2. 473개 authored scene 전체를 사람이 직접 수동 플레이로 전부 검수한 것은 아니다. 자동 coverage와 coherence audit은 이를 보완하지만 완전한 인간 편집 검수와 동일하지는 않다.
3. 공식 GitHub Release는 이 문서 작성 시점까지 과거 공개 버전에 머물러 있다. 0.5.3 release branch의 최종 green/Windows artifact 확인 후 main/tag 단계에서 정리한다.

<!-- CI retry marker: HUMAN TRACE deterministic ownership coverage -->
