# QA REPORT — ASTRA 0.4.2

검증일 2026-09-20 · Godot 4.7.2 Standard · Windows x86_64
이 문서는 pair_history/echo_state 재설계, 챕터별 방·완료조건·AP 데이터화,
선택 effect 확장, `content_audit.gd`의 실제 게이트 승격 직후의 상태를 기록합니다.
이전 0.4.1 보고서의 수치는 더 이상 유효하지 않습니다.

---

## 자동 테스트

헤드리스로 각 스위트를 개별 실행합니다. 릴리스 빌드(`tools/build_windows.ps1`)는 이 중
핵심 스위트를 통과해야 exe를 내보냅니다.

| 스위트 | 무엇을 검사하는가 | 검사 수 | 결과 |
|---|---|---|---|
| `run_tests.gd --games=40` | 조사 규칙, 사건 생성 공정성, 봇 시뮬레이션 720판 | 36,445 | OK |
| `voyage_tests.gd` | voyage 저장/복원, 로스터 진행, 장면 고유성·다양성 | 348 | OK |
| `campaign_tests.gd` | 해금 순서와 캠페인 진행 | 108 | OK |
| `redesign_tests.gd` | 튜토리얼 게이팅, 초상 자산 존재, 챕터별 AP 예산 | 932 | OK |
| `social_tests.gd` | 온보딩 형태, 해금 순서, 도움말 게이팅, 주장 기록, 대질, 저장 호환 | 926 | OK |
| `replay_variety.gd` (시드 200) | Null·짝·무고한 거짓말쟁이 분포, 대사 반복률 | 42 | OK |
| `story_consistency_tests.gd` | 첫판 회귀, 7개 장 연속 플레이 서사 정합성 | 96 | OK |
| `ui_smoke.gd` | 실제 UI를 콜드 오픈부터 결과까지 주행 | 스크립트 오류 0 | OK |
| `content_audit.gd` (이번 패스에서 실제 게이트로 승격) | 캐릭터별 장면/태그/선택 다양성, pair_history 대칭성, CALIBRATION/DEAD_AIR 구조 | 10개 검사군 | **2 FAIL**(아래 참고), 2 WARN |
| `compatibility_test.gd` | 0.3.0 저장 호환 | — | **환경상 미확인**(고정 fixture 없음) |
| `visual_qa.gd` / `voyage_visual.gd` | 렌더러 스크린샷 | — | **환경상 미확인**(이 헤드리스 셸에 표시 장치 없음) |

`content_audit.gd`는 의도적으로 `tools/build_windows.ps1`에 연결하지 않았습니다. 아래 두 FAIL은
알려진 미완료 콘텐츠 작업(캐릭터별 장면 재배분, 다단계 개인 이벤트)이며, 이 때문에 정상적으로
동작하는 빌드를 막을 이유가 없다고 판단했습니다. `godot --headless --path . --script
res://tests/content_audit.gd`로 직접 실행해 현재 상태를 그대로 볼 수 있습니다.

## content_audit.gd 실제 출력 (요약)

| # | 검사 | 결과 |
|---|---|---|
| 1 | 8명 전원 동일 tag set인가 | OK — 미라·루칸만 `pair` 태그가 없어 이미 다름 |
| 2 | 캐릭터별 장면 수가 기계적으로 동일한가 | **FAIL** — 20~22개로 편차가 여전히 좁음 |
| 3 | 선택 effect가 7종 이하로 후퇴했는가 | OK — 11종(`confront`/`withhold`/`keep_copy`/`promise` 추가) |
| 4 | 같은 문장 시작이 5회 이상 반복되는가 | WARN — "◯◯가/이" 형태가 캐릭터당 최대 21회 |
| 5 | pair 장면 고유 조합 수 | WARN — 10쌍(28쌍 중), pair_history는 전 쌍 커버 |
| 6 | personal:everyday 비율이 캐릭터별로 다른가 | WARN — 8명 모두 5:3으로 동일 |
| 7 | 캐릭터당 개인 이벤트 수 | **FAIL** — 8명 모두 1개(§18은 4~7개 요구) |
| 8 | `pair_key()`가 A/B 대칭인가 | OK |
| 9 | CALIBRATION이 MEETING/VOTE/NIGHT에 도달하는가 | OK — 도달하지 않음 |
| 10 | DEAD_AIR 회의 예산이 가벼운가 | OK — `meeting_actions_max() == 1`(0으로 두면 NPC 투표가 플레이어 증거를 전혀 못 듣고 갈라져 사건이 사실상 풀리지 않는 회귀를 발견해 1로 조정) |

## 첫판(CALIBRATION) 수치 — `story_consistency_tests.gd::test_first_play_regression`로 자동 검증

| 항목 | 수치 |
|---|---|
| 필수 방문 장소 | 1 (의료실만; 이동 막대 자체가 1개 버튼) |
| 필수 조사 | 1 (전원 패널) — 완료 전에는 다른 조사 지점 노출 안 함 |
| 만나야 하는 동료 | 4명(미라·준·다렌·노아), 전원 의료실 안에서 자동 합류 — 이동 불필요 |
| 회의/투표/밤 | 도달하지 않음(`finish_voyage`가 EXPLORE → RESULT로 직행) |
| 실패 상태 | 없음(승패 판정 없이 `outcome == "CONTINUE"`) |
| 소프트락 | 없음(`voyage_can_finish()`가 항상 유한한 행동 후 참이 됨을 테스트로 확인) |

## 챕터별 방·완료조건·AP (이번 패스에서 데이터화)

| 장 | 방 목록 | 완료 조건 | 조사/대화/회의 AP |
|---|---|---|---|
| CALIBRATION | 의료실 1곳 | 동료 4명 전원 만남 | 시스템 미적용 |
| DEAD_AIR | 의료실·통신실·기록보관실 | 노아를 만남 + 방 2곳 방문 | 2 / 1 / 1 |
| GLASS_GARDEN | 의료실·보안허브·수목구역 | 세나를 만남 + 방 2곳 방문 | 2 / 2 / 1 |
| ECHO_WARD | (기존 5개 기본 방 + 각 인물 집) | 방 2곳 + 동료 4명(일반 규칙) | 2 / 2 / 1 |
| SILENT_ORBIT | 〃 | 〃 | 3 / 3 / 2 |
| RED_SHIFT | 〃 | 〃 | 3 / 3 / 2 |
| LAST_LIGHT | 〃 | 〃 | 3 / 3 / 2 |

DEAD_AIR/GLASS_GARDEN에서 실제 집이 목록에 없는 승무원(예: DEAD_AIR의 준)은
`AstraVoyageContent.home_room()`을 통해 그 장의 첫 방(의료실)에 자동으로 모입니다 —
플레이어가 찾아다닐 필요가 없습니다.

## 단계별 로스터·Null 구조

| 장 | 로스터 | Null |
|---|---|---|
| CALIBRATION | 4 | 1 |
| DEAD_AIR | 4 | 1 |
| GLASS_GARDEN | 5 | 1 |
| ECHO_WARD | 6 | 1 |
| SILENT_ORBIT | 7 | 2 |
| RED_SHIFT | 8 | 2 |
| LAST_LIGHT | 8 | 2 |

## 관계·잔향 시스템 — 이번 세션에서 새로 확인한 것

- **pair_history 대칭성**: `AstraCrewCatalog.pair_key(a,b) == pair_key(b,a)`가 8×7명 전 조합에서
  성립함을 `content_audit.gd` #8과 `story_consistency_tests`가 함께 검사합니다. 과거에는
  `id+":"+other` 방향별 키를 각각 랜덤 생성해 A와 B가 다른 과거를 기억할 수 있었습니다.
- **echo_state 마이그레이션**: 구버전 스칼라 echo 값(float)을 읽으면 `familiarity` 축으로 자동
  변환되고, 나머지 네 축은 0에서 시작합니다. 저장 필드 이름(`voyage["echo"]`)은 그대로 유지해
  기존 세이브의 `_valid_snapshot()` 검사가 깨지지 않습니다.
- **레거시 문구 정리**: `case_catalog.gd`의 "archive reconstructs... identity models" 주석,
  CALIBRATION 원본 로스터의 다렌 누락, `opening_view.gd`의 "damaged recorder"/"killed" 설계
  주석, `story_content.gd`에 남아 있던 "동률에 탐사요원의 대상을 우선" 문구,
  `docs/UI_REFERENCE_NOTES.md`의 "2표" 서술, `tests/bots.gd`의 "identity models" 주석을
  현재 규칙에 맞게 고쳤습니다.

## 저장 호환

| 항목 | 결과 |
|---|---|
| 진행 저장 v1/v2/v3 | 그대로 읽음(`voyage_tests.gd`가 왕복 저장을 매 장마다 검사) |
| 메타 저장(해금·기억) | v8, `voyage_memory` 라운드트립 확인 |
| pair_history / echo_state 라운드트립 | `same_state()` 재귀 비교로 중첩 Dictionary까지 검사 |
| 내부 캐릭터 ID(mira/rho/dax/…) | 화면 표시와 분리 유지, 변경 없음 |
| 0.3.0 원본 저장(`compatibility_test.gd`) | 이번 환경에 전용 fixture가 없어 미확인 |

## 1표 규칙

`AstraGameSession.PLAYER_VOTE_WEIGHT == 1`이며, 동률 시 아무도 격리되지 않습니다. 도달 불가능한
레거시 튜토리얼 함수(`story_content.gd`)에 남아 있던 "동률에 탐사요원의 대상을 우선" 문구도
이번 패스에서 고쳤습니다 — 이제 현재 규칙과 모순되는 문장은 저장소 전체에 없습니다.

## 반복 플레이 측정 (`replay_variety.gd`, 사건당 200시드)

| 지표 | 결과 |
|---|---|
| 10판 창 평균 서로 다른 Null 짝 | 8.9 |
| Null 짝 분포 | 최소 7쌍 이상 등장 |
| 무고한 거짓말쟁이 분포 | 최소 7명 이상 등장 |
| 레이아웃 다양성 | 10종 |

## 남은 문제 (`content_audit.gd`가 FAIL/WARN으로 정확히 보고)

| 문제 | 영향 | 비고 |
|---|---|---|
| 캐릭터별 장면 수 20~22개로 균일, 태그 구조도 대부분 동일 | §10이 요구하는 "캐릭터마다 다른 장면 분포"가 아직 아님 | 대규모 대사 집필 필요, 이번 세션도 범위 밖(FAIL) |
| 개인 이벤트가 캐릭터당 1개(`private_events.gd`) | §18이 요구하는 4~7개 다단계 개인 이벤트 전 | 미착수(FAIL) |
| NPC pair 장면 10개, 고유 조합 10쌍 | §12가 요구하는 관계망보다 얕음(단, pair_history는 전 쌍 커버) | 미착수(WARN) |
| personal:everyday 비율이 8명 모두 동일 | §11이 요구하는 캐릭터별 분화 전 | 미착수(WARN) |
| DEAD_AIR/GLASS_GARDEN을 제외한 나머지 4개 캠페인 장은 방 목록을 그대로 둠 | §4가 예시한 ECHO_WARD~LAST_LIGHT 방 축소는 미적용 | 위험도 대비 실익 판단, 기존 room-travel 테스트와 충돌 회피 |
| DEAD_AIR 등에서도 BRIEFING→MEETING→VOTE 전 단계가 상태 기계상 유지됨(AP만 0으로) | §H/§7이 예시한 "chapter phase flow 배열로 MEETING/VOTE 자체를 제거" 아직 아님 | 승패 판정이 VOTE에 강하게 결합돼 있어 더 큰 재설계 필요 — AP를 0으로 낮춰 실질적으로 "지켜보기만" 하도록 완화 |
| `interrogation_view.gd`의 옵션 병합 로직이 여전히 도달 불가능한 `tutorial_active()`에 묶여 있음 | 죽은 코드, 동작에 영향 없음 | 정리 대상으로 남김 |
| scene selection이 `AstraVoyageContent.SCENES` 전체를 매번 선형 검색 | §48이 요구하는 speaker별 인덱스 없음 | 장면 수가 실질적으로 늘지 않아 우선순위 낮음 |
| `visual_qa.gd`/`voyage_visual.gd`/`compatibility_test.gd` | 이 세션의 헤드리스 셸에서 검증 불가 | 로컬 Godot 에디터 또는 원본 0.3.0 fixture 필요 |

## 알려진 비이슈

- `run_tests`의 `passive_rate < 0.2`는 시드 40개 이상에서만 엄격하게 적용됩니다. 모든 사건·조사
  방식이 같은 시드 범위를 쓰므로 유효 표본은 시드 수입니다. 릴리스 빌드는 40시드를 씁니다.
