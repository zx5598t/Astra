# QA REPORT — ASTRA 0.4.1

검증일 2026-09-19 · Godot 4.7.2 Standard · Windows x86_64
이 문서는 첫판/둘째판 재설계와 캠페인 6개 장의 살인사건 플롯 제거(구 Ives/Orin/Sael/Tess/Ren/Ari)
직후의 상태를 기록합니다. 이전 0.4.0 보고서의 수치는 더 이상 유효하지 않습니다.

---

## 자동 테스트

헤드리스로 각 스위트를 개별 실행합니다. 릴리스 빌드(`tools/build_windows.ps1`)는 이 중
핵심 스위트를 통과해야 exe를 내보냅니다.

| 스위트 | 무엇을 검사하는가 | 검사 수 | 결과 |
|---|---|---|---|
| `run_tests.gd --games=40` | 조사 규칙, 사건 생성 공정성, 봇 시뮬레이션 720판 | 36,445 | OK |
| `voyage_tests.gd` | voyage 저장/복원, 로스터 진행, 장면 고유성·다양성 | 346 | OK |
| `campaign_tests.gd` | 해금 순서와 캠페인 진행 | 108 | OK |
| `redesign_tests.gd` | 튜토리얼 게이팅, 초상 자산 존재 | 951 | OK |
| `social_tests.gd` | 온보딩 형태, 해금 순서, 도움말 게이팅, 주장 기록, 대질, 저장 호환 | 930 | OK |
| `replay_variety.gd` (시드 200) | Null·짝·무고한 거짓말쟁이 분포, 대사 반복률 | 42 | OK |
| `story_consistency_tests.gd` (신규) | 첫판 회귀(§21), 7개 장 연속 플레이 서사 정합성(§S) | 99 | OK |
| `ui_smoke.gd` | 실제 UI를 콜드 오픈부터 결과까지 주행 | 스크립트 오류 0 | OK |
| `content_audit.gd` (신규, report-only) | 캐릭터별 장면/태그/선택 다양성 — 항상 종료 코드 0 | — | 아래 "남은 문제" 참고 |
| `compatibility_test.gd` | 0.3.0 저장 호환 | — | **환경상 미확인**(고정 fixture 없음, 이번 세션 변경과 무관) |
| `visual_qa.gd` / `voyage_visual.gd` | 렌더러 스크린샷 42장 | — | **환경상 미확인**(이 헤드리스 셸에 표시 장치 없음, 렌더링 대기에서 정지) |

## 첫판(CALIBRATION) 수치 — `story_consistency_tests.gd::test_first_play_regression`로 자동 검증

| 항목 | 수치 |
|---|---|
| 필수 방문 장소 | 1 (의료실만; 이동 막대 자체가 1개 버튼) |
| 필수 조사 | 1 (전원 패널) — 완료 전에는 다른 조사 지점 노출 안 함 |
| 만나야 하는 동료 | 4명(미라·준·다렌·노아), 전원 의료실 안에서 자동 합류 — 이동 불필요 |
| 회의/투표/밤 | 도달하지 않음(`finish_voyage`가 EXPLORE → RESULT로 직행) |
| 실패 상태 | 없음(승패 판정 없이 `outcome == "CONTINUE"`) |
| 소프트락 | 없음(`voyage_can_finish()`가 항상 유한한 행동 후 참이 됨을 테스트로 확인) |

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

`voyage_tests.gd`와 `story_consistency_tests.gd` 양쪽에서 `AstraVoyageContent.awake_roster(case_id)`와
`case_data.roster`의 일치를 매 장마다 확인합니다.

## 서사 정합성 — 이번 세션에서 새로 확인한 것

- **구 살인사건 플롯 제거**: `case_catalog.gd`의 캠페인 6개 장(DEAD_AIR~LAST_LIGHT)이 쓰던
  0.3.x/0.4.0 시절 피해자(함장 Ives, 연구원 Orin, 의료 책임자 Sael, 정비사 Tess, 관측 책임자 Ren,
  항해 기록관 Ari)와 그에 딸린 hook/room/op을 전부 제거하고, voyage 레이어가 실제로 보여주는
  미스터리(목적지 이중 기록, 세나·준의 엇갈린 근무 기록, 겹친 신호, 19년 전 도착 기록, 정착용으로
  분류된 표본, 불안정한 전력 계통)에 맞춰 다시 썼습니다. `victim`/`victim_role` 필드는
  `subject`/`subject_role`로 이름을 바꿨습니다.
  `story_consistency_tests.gd`가 7개 장의 `case_data` 전체를 직렬화해 옛 이름이 전혀 등장하지
  않는지 매 실행마다 검사합니다.
- **회귀 버그 수정**: `get_case()`가 로스터 7명 미만인 장에서 `ops`를 1개로 잘라내면서도
  `challenge.target`은 옛 값(2) 그대로 두어 DEAD_AIR의 "두 조작의 실행 로그 확보" 목표가
  구조적으로 달성 불가능했던 문제를 발견해 수정했습니다(`records` 타입 챌린지는 이제 `ops.size()`로
  자동 상한).
- **루프 리셋 화면 다양화**: 7개 장 전부가 같은 "같은 목소리 / 손목에는 반창고가 없다" 문구로
  끝나던 것을, 장마다 다른 제목·물리적 디테일로 바꿨습니다(`AstraVoyageContent.reset_framing`).

## 저장 호환

| 항목 | 결과 |
|---|---|
| 진행 저장 v1/v2/v3 | 그대로 읽음(`voyage_tests.gd`가 왕복 저장을 매 장마다 검사) |
| 메타 저장(해금·기억) | v8, `voyage_memory` 라운드트립 확인 |
| 내부 캐릭터 ID(mira/rho/dax/…) | 화면 표시와 분리 유지, 변경 없음 |
| 0.3.0 원본 저장(`compatibility_test.gd`) | 이번 환경에 전용 fixture가 없어 미확인. 실패 사유는
  fixture 누락이며 이번 세션의 코드 변경과는 무관합니다. |

## 1표 규칙

`AstraGameSession.PLAYER_VOTE_WEIGHT == 1`이며, 동률 시 아무도 격리되지 않습니다
(`game_session.gd`의 `phase_hint()`가 이 규칙을 그대로 안내). 구버전의 "탐사요원 2표·동률 우선권"
문구는 `story_content.gd`의 도달 불가능한 레거시 튜토리얼 함수 안에만 남아 있었고, 이번 패스에서
현재 규칙에 맞게 고쳤습니다.

## 반복 플레이 측정 (`replay_variety.gd`, 사건당 200시드)

| 지표 | 결과 |
|---|---|
| 10판 창 평균 서로 다른 Null 짝 | 8.9 |
| Null 짝 분포 | 최소 7쌍 이상 등장 |
| 무고한 거짓말쟁이 분포 | 최소 7명 이상 등장 |
| 레이아웃 다양성 | 10종 |

## 남은 문제 (이번 세션에서 손대지 않음 — `content_audit.gd` 실제 출력)

| 문제 | 영향 | 비고 |
|---|---|---|
| 8명 전원 동일 20~21개 태그 세트, 장면 수 20~22개로 균일 | §10이 요구하는 "캐릭터마다 다른 장면 분포"가 아직 아님 | 대규모 대사 집필 필요, 이번 세션 범위 밖 |
| 선택 effect가 여전히 7종(help/record/share/wait/observe/defend/hide) | §7이 요구하는 상태 변화형 선택 확장 전 | 미착수 |
| NPC pair 장면 10개, 고유 조합 10쌍 | §12가 요구하는 관계망보다 얕음 | 미착수 |
| 개인 이벤트/캐릭터가 사실상 1단계(`private_events.gd`) | §11이 요구하는 다단계 개인 이벤트 전 | 미착수 |
| 과거 관계가 "오래된 동료" / "처음 함께 일함" 이진 랜덤(`begin_voyage`) | §13이 요구하는 pair_history 데이터 구조 전 | 미착수 |
| 감정 잔향이 단일 `bonds`/`echo` 스칼라(캐릭터별 분화 없음) | §14가 요구하는 trust/conflict/grief 잔향 분리 전 | 미착수 |
| DEAD_AIR 등 초반 장에서도 BRIEFING→MEETING→VOTE 전 단계가 항상 강제됨 | §H가 요구하는 "장마다 회의/투표를 선택적으로" 아직 아님 | 승패 공정성 수식이 8인 기준으로 조정되어 있어 재설계 필요 |
| `interrogation_view.gd`의 옵션 병합 로직이 여전히 도달 불가능한 `tutorial_active()`에 묶여 있음 | 죽은 코드, 동작에 영향 없음 | 정리 대상으로 남김 |
| `visual_qa.gd`/`voyage_visual.gd`/`compatibility_test.gd` | 이 세션의 헤드리스 셸에서 검증 불가 | 로컬 Godot 에디터 또는 원본 0.3.0 fixture 필요 |

## 알려진 비이슈

- `run_tests`의 `passive_rate < 0.2`는 시드 40개 이상에서만 엄격하게 적용됩니다. 모든 사건·조사
  방식이 같은 시드 범위를 쓰므로 유효 표본은 시드 수입니다. 릴리스 빌드는 40시드를 씁니다.
