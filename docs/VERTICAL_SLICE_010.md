# ASTRA 0.1.0 Vertical Slice

0.1.0은 기능을 더 쌓는 버전이 아니라, 지금까지 구현한 시스템을 하나의 작은 캠페인으로 묶는 첫 Vertical Slice다.

## 플레이 구조

1. INCIDENT ARCHIVE에서 사건을 선택한다.
2. Investigator Protocol을 선택한다.
3. 현장 조사 → 개인 심문 → 공개 회의 → Notebook 가설 연결을 진행한다.
4. 격리 투표 전에 CASE THEORY를 제출한다.
5. 최대 3 Day 동안 사건을 해결한다.
6. 사건 종료 후 CASE THEORY 점수와 Archive 진행도를 확인한다.
7. 사건을 완료하면 다음 Incident가 해금된다.

## Incident progression

- INCIDENT ZERO · DEAD AIR — 처음부터 해금
- INCIDENT ONE · GLASS GARDEN — Dead Air 1회 완료 후 해금
- INCIDENT TWO · ECHO WARD — Glass Garden 1회 완료 후 해금

클리어한 사건은 언제든 다시 플레이할 수 있다. Null 역할과 주요 증거 대상은 Seed에 따라 다시 배치된다.

## Investigator Protocol

### ANALYST
- 현장 조사 행동력 +1
- 더 많은 위치를 직접 확인하는 플레이에 적합

### EMPATH
- 개인 심문 행동력 +1
- 모든 생존 Crew의 초기 플레이어 신뢰가 소폭 상승
- 대화와 관계 변화를 더 많이 확인하는 플레이에 적합

### AUDITOR
- 사건 구조를 설명하는 COMMON / context 기록 1개를 시작 시 확보
- 초기 Case Confidence를 소폭 확보
- 증거 연결부터 빠르게 시작하는 플레이에 적합

Protocol은 정답을 알려주지 않으며, 숨겨진 역할이나 핵심 범인 정보를 직접 공개하지 않는다.

## Persistent Archive v4

기존 저장 데이터를 유지하면서 다음 항목을 추가한다.

- 사건별 완료 횟수
- 사건별 최고 CASE THEORY 점수
- 사건별 최고 평가 라벨
- 3개 사건 캠페인 진행도

기존 Insight, 관계 이벤트, 개인 이벤트 선택, 전체 최고 점수 기록은 그대로 유지된다.

## Validation

0.1.0 CI는 다음을 모두 검사한다.

- Godot import 중 SCRIPT ERROR / Parse Error 없음
- 전체 핵심 GDScript 파서 검사
- 기존 CASE THEORY smoke test
- 0.1.0 캠페인 해금 smoke test
- Dead Air / Glass Garden / Echo Ward 각각 2 Null / 8 Evidence / 4 Location 초기화 확인
- 기본 main scene headless boot
