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

PR CI 완료 후 실제 check 수, bot 비율, content audit FAIL/WARN, Linux/Windows validation 결과를 이 섹션에 기록한다. 기존 threshold는 완화하지 않는다.

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
