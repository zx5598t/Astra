# ASTRA 0.0.9 — CASE ANALYSIS

AI-native social deduction RPG 프로토타입. 0.0.9는 플레이어의 추리를 실제 제출/평가 시스템으로 전환하는 버전입니다.

## 핵심 변경
- 매 Day 투표 전 **CASE THEORY** 제출
- 두 명의 용의자 + 확신도 기록
- 사건 종료 후 **추리 정확도 100점 평가 / 등급**
- 투표와 추리 가설을 별도 기록해 단순 다수결 게임에서 분리
- Dead Air / Glass Garden / Echo Ward에 **Incident Stage** 연출 추가
- 피해자 / 봉쇄 상태 / 조사 구역 / 목표를 시각 카드로 표시
- 8명 개인 이벤트를 **3지선다 Private Scene**으로 확장
- Archive 저장 v3: 이론 제출 수 / 완전 적중 수 / 최고 추리점수 보존
- CI smoke test: 상태 생성 → 조사 → 가설 제출까지 자동 검사

## 현재 플레이 루프
브리핑 → 현장 조사 → 개인 심문 → 공개 회의 → 추리 보드 → CASE THEORY 제출 → 격리 투표 → 최대 3 Day → 사건 결과 + 추리 평가

## 실행
Godot 4.7.2 stable 권장. `project.godot` Import 후 F5.

AI 백엔드 없이도 전체 게임은 규칙 기반 fallback으로 플레이 가능합니다.
