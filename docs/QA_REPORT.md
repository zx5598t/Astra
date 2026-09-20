# QA REPORT — ASTRA 0.5.0

검증일 2026-09-20 · Godot 4.7.2 stable · Linux + Windows x86_64

0.5.0은 `release/0.5.0` 브랜치에서 검증한다. 일반 규칙/저장/UI 테스트뿐 아니라
첫판 서사, 7개 장 연속 진행, 콘텐츠 수량/관계 구조, Windows 실제 실행과 Windows 배포 ZIP 생성까지
릴리스 게이트에 포함했다.

---

## 현재 자동 검증

| 검사 | 결과 |
|---|---|
| 프로젝트 import + 전 GDScript parse | OK |
| 규칙·사건 생성·밸런스 | OK |
| 캠페인·미션·저장 호환 | OK |
| UI smoke (타이틀 → 사건 → 결과) | OK |
| 가설·밤 행동·자산 회귀 | OK |
| 온보딩·해금·Claim Ledger | OK |
| 반복 플레이·역할 분포 | OK |
| voyage 진행·기억·아이템 | OK |
| 첫판 + 7개 장 연속 서사 정합성 | OK |
| 0.5.0 content audit | **0 FAIL / 2 WARN** |
| Windows Godot 4.7.2 import | OK |
| Windows 모델 테스트 | OK |
| Windows UI smoke | OK |
| Windows 메인 장면 부팅 | OK |
| Windows 실제 release-candidate export | **OK** |

GitHub Actions에서 실제로 생성된 Windows 후보 빌드 아티팩트:
`ASTRA-0.5.0-windows-rc` — 약 92.5 MB.

---

## 0.5.0 핵심 불변조건

- 투표자와 투표 대상은 ACTIVE 승무원만 가능하다.
- 자기 자신에게 투표할 수 없다.
- 장기수면 격리 또는 생체 신호 두절 상태의 승무원은 발언·투표·밤 행동 대상에서 빠진다.
- 플레이어는 회의 발언이 가능하지만 비활성 NPC는 회의 feed에 들어갈 수 없다.
- 위 규칙은 UI가 아니라 `AstraGameSession` 모델에서도 다시 검사한다.
- content audit은 300개 시드에서 이 규칙을 반복 검증한다.

## 첫판과 단계별 시스템 노출

| 장 | 핵심 시스템 |
|---|---|
| CALIBRATION | 전원 패널 1회 + 미라와 직접 대화 1회. 회의/투표/밤 없음 |
| DEAD_AIR | 조사 + 대화 |
| GLASS_GARDEN | 조사 + 대화 + 짧은 공개 확인 |
| ECHO_WARD | 장기수면 격리 투표 + 첫 밤 보호/백업 도입 |
| SILENT_ORBIT 이후 | 감시·휴식 등 밤 선택과 더 긴 회의/추리 구조 확장 |

브리핑과 상단 단계 표시도 실제로 해당 장에서 사용하는 단계만 노출한다. 아직 배우지 않은 시스템을
미리 보여 주지 않는다.

## 캐릭터·관계 콘텐츠

- 탐색용 authored scene: **280개**
- 캐릭터별 장면 수: 약 **28~36개**로 서로 다르게 배분
- 개인 이벤트: **총 40개**, 캐릭터당 4~6개
- 핵심 관계 8쌍: 쌍마다 최소 2개의 전용 authored scene
- 3인 대화: 4개
- `pair_history`: 순서 독립적인 canonical pair key 사용
- `echo`: familiarity / trust / protection / conflict / grief 5축 유지

## 회의·대화

- 회의는 논점 단위로 연결되고 지목된 인물이 바로 답하는 구조를 사용한다.
- 화면에서 **새 논점 / 직전 발언에 대한 답**을 표시한다.
- 전체 공개 발언은 Claim Ledger에 남아 나중에 비교할 수 있다.
- 자동 진행은 기본 OFF이며 중요한 발언에서 실제로 일시정지한다.
- 심문 반응은 숨은 숫자 대신 **납득함 / 흔들림 / 아직 저항함 / 불확실 / 화남**으로 표시한다.

## 저장·배포

- 기존 저장 필드와 내부 캐릭터 ID는 유지한다.
- pair_history / echo 중첩 데이터는 저장 왕복 검증을 수행한다.
- Windows 배포 전에 `story_consistency_tests.gd`와 `content_audit.gd`도 다시 실행한다.
- release 브랜치에서는 GitHub의 Windows 가상 PC가 실제 export template을 설치하고
  `tools/build_windows.ps1`을 실행해 ZIP과 SHA-256을 만든다.

## 남은 WARN

`content_audit.gd`의 FAIL은 현재 0개다. 남은 WARN은 두 가지다.

1. 많은 장면의 행동문이 여전히 "미라가 / 준이 / 노아가 ..."처럼 인물 이름으로 시작한다.
   기능 문제는 아니지만 장기적으로 문장 시작 리듬을 더 다양화할 수 있다.
2. personal:everyday 장면 비율이 캐릭터마다 충분히 다르지 않다.
   총량과 캐릭터별 수는 이미 분화되어 있으나 태그 비율까지 더 개성 있게 조정할 여지가 있다.

두 항목 모두 릴리스 차단 문제는 아니며, 규칙·저장·Windows 실행/배포 검증은 통과한다.
