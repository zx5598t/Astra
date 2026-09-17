# ASTRA 0.1.0 — FIRST VERTICAL SLICE

AI-native social deduction RPG. 0.1.0은 지금까지 만든 추리·관계·노트북·투표 시스템을 하나의 작은 캠페인으로 묶는 첫 Vertical Slice입니다.

## 0.1.0 핵심
- **INCIDENT ARCHIVE** 시작 화면 추가
- Dead Air → Glass Garden → Echo Ward 순차 해금
- 클리어한 사건은 자유롭게 재조사 가능
- 사건별 완료 상태와 **최고 CASE THEORY 점수** 표시
- 3가지 **Investigator Protocol** 추가
  - ANALYST: 조사 행동력 +1
  - EMPATH: 심문 행동력 +1, 초기 신뢰 소폭 상승
  - AUDITOR: 사건 구조용 기본 기록 1개 확보
- Archive Save v4: 사건별 최고 추리점수/평가 저장
- 사건 종료 후 다음 해금 사건과 캠페인 진행도 표시
- Vertical Slice 전용 CI: 해금 규칙 + 3개 사건 초기화 자동 검증

## 현재 플레이 루프
INCIDENT ARCHIVE → Protocol 선택 → 브리핑 → 현장 조사 → 개인 심문 → 공개 회의 → Investigator Notebook → CASE THEORY 제출 → 격리 투표 → 최대 3 Day → 사건 결과/추리 평가 → 다음 Incident 해금

## 사건
1. INCIDENT ZERO · DEAD AIR — 처음부터 플레이 가능
2. INCIDENT ONE · GLASS GARDEN — Dead Air 완료 후 해금
3. INCIDENT TWO · ECHO WARD — Glass Garden 완료 후 해금

각 사건의 Null 2명과 주요 증거 대상은 Seed에 따라 다시 배치됩니다.

## 실행
1. Godot 4.7.2 stable 실행
2. Project Manager에서 `project.godot` Import
3. Import & Edit
4. F5 또는 우측 상단 ▶ Run Project

AI 백엔드는 선택 사항입니다. 서버가 없어도 규칙 기반 fallback으로 전체 플레이 루프가 동작합니다.

상세 설계: `docs/VERTICAL_SLICE_010.md`
