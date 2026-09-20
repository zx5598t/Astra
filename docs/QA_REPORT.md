# QA REPORT — ASTRA 0.5.3 HEARTBEAT

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

0.5.3 버전 승격 전 동일 코드 기준 release-candidate build와 exported EXE boot는 이미 통과했다. 최종 `VERSION=0.5.3` 승격 후 같은 pipeline을 다시 실행해 `ASTRA-0.5.3-windows.zip`을 생성한다.

## 남은 실제 문제

1. action prose opener 반복 WARN 1건.
2. 473개 authored scene 전체를 사람이 직접 수동 플레이로 전부 검수한 것은 아니다. 자동 coverage와 coherence audit은 이를 보완하지만 완전한 인간 편집 검수와 동일하지는 않다.
3. 공식 GitHub Release는 이 문서 작성 시점까지 과거 공개 버전에 머물러 있다. 0.5.3 release branch의 최종 green/Windows artifact 확인 후 main/tag 단계에서 정리한다.
