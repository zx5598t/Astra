# ASTRA Deduction System — 0.0.9

## 목적
투표와 추리를 분리한다. 플레이어는 매 Day 투표 직전에 두 명의 용의자로 구성된 `CASE THEORY`를 제출한다.

## 규칙
- Primary/Secondary suspect는 서로 다른 인물이어야 한다.
- 격리된 인물도 전체 사건 가설에는 포함할 수 있다.
- 제출 시점에는 정답 여부를 공개하지 않는다.
- 실제 격리 투표는 별도로 한 명에게 한다.
- 마지막으로 제출한 가설이 사건 종료 평가에 사용된다.

## 평가 100점
- 실제 Null 적중: 최대 60점
- 플레이어가 추리 보드에서 만든 의심 연결 + 발견한 직접 모순 활용: 최대 30점
- 확신도 calibration: -10~+10점

## 등급
- 90+: S-RANK OBSERVATION
- 75+: A-RANK THEORY
- 55+: B-RANK THEORY
- 35+: C-RANK THEORY
- 이하: FRAGMENTED

## 설계 원칙
가설 제출은 TruthEngine을 수정하지 않는다. 게임 정답, NPC 기억, 의심도, 투표 결과는 기존 권위 계층에 남는다.
