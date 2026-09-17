# ASTRA 0.1.1 — CHARACTER PERFORMANCE

AI-native social deduction RPG. 0.1.1은 0.1.0 Vertical Slice의 구조를 유지하면서 **캐릭터 존재감과 회의 연출, 화면·사운드 피드백**을 강화한 업데이트입니다.

## 0.1.1 핵심
- 캐릭터 선택 시 초상화 **fade / scale-in** 연출
- 초상화 위에 이름·직업·현재 감정 슬롯 표시
- 심문 선택 후 `ALIBI RESPONSE`, `EVIDENCE REACTION`, `PRESSURE RESPONSE` 등 대화 큐 표시
- 공개회의 진입 시 최대 4개 핵심 발언을 **Speaker Spotlight**로 순차 재생
- 발언 / 반박 / 끼어들기를 서로 다른 meeting tag로 표시
- BRIEFING / INVESTIGATION / INTERROGATION / MEETING / VOTE / RESULT 단계 전환 배너 추가
- 사건별 시작 사운드와 선택·심문·단계 전환·완료 절차음 추가
- 증거 발견 시 `EVIDENCE ACQUIRED` 연출 강화
- 새 연출 전용 headless smoke test 추가

## Vertical Slice 플레이 루프
INCIDENT ARCHIVE → Protocol 선택 → 브리핑 → 현장 조사 → 개인 심문 → 공개 회의 → Investigator Notebook → CASE THEORY 제출 → 격리 투표 → 최대 3 Day → 사건 결과/추리 평가 → 다음 Incident 해금

## 사건
1. INCIDENT ZERO · DEAD AIR — 처음부터 플레이 가능
2. INCIDENT ONE · GLASS GARDEN — Dead Air 완료 후 해금
3. INCIDENT TWO · ECHO WARD — Glass Garden 완료 후 해금

각 사건의 Null 2명과 주요 증거 대상은 Seed에 따라 다시 배치됩니다.

## Investigator Protocol
- **ANALYST** — 조사 행동력 +1
- **EMPATH** — 심문 행동력 +1, 초기 신뢰 소폭 상승
- **AUDITOR** — 사건 구조용 기본 기록 1개 확보

## 실행
1. Godot 4.7.2 stable 실행
2. Project Manager에서 `project.godot` Import
3. Import & Edit
4. F5 또는 우측 상단 ▶ Run Project

AI 백엔드는 선택 사항입니다. 서버가 없어도 규칙 기반 fallback으로 전체 플레이 루프가 동작합니다.

상세 설계: `docs/VERTICAL_SLICE_010.md`, `docs/PRESENTATION_011.md`
