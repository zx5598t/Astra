# ASTRA 0.0.4 — INCIDENT ZERO: DEAD AIR

**Social Pressure** 업데이트. ASTRA의 핵심인 “사람이 사람을 의심하고, 관계 때문에 판단이 흔들리는 느낌”을 실제 게임 규칙에 넣기 시작한 버전입니다.

## 0.0.4 핵심
- 8명 승무원 / 4F + 4M
- 동적 질문 선택지(Question Lattice)
- NPC 간 호감·마찰 관계
- 공개 회의의 자율 발언 / 반박 / 끼어들기
- 관계가 투표 판단에 약하게 영향
- Dossier에서 주요 관계 확인
- AI 연결용 Context Builder / Output Validator 강화
- 외부 AI 없이도 전체 플레이 가능

## 플레이 흐름
`브리핑 → 조사 → 개인 심문 → 공개 회의 → 격리 투표 → 결과`

개인 심문에서 이제 모든 NPC에게 동일한 버튼만 나오지 않습니다. 확보한 증거, 신뢰도, 스트레스, 이전 고정 발언에 따라 **모순 지적 / 둘만의 판단 요청 / 현재 의심 대상을 추궁** 같은 질문이 나타납니다.

공개 회의에서는 각 NPC가 자신의 의심을 말하고, 다른 승무원이 관계와 성향에 따라 끼어들거나 반박할 수 있습니다.

## AI 설계 원칙
`TruthEngine`만 사건의 진실을 결정합니다. 향후 연결되는 LLM에는 NPC가 알 수 있는 사실과 공개된 증거만 전달하며, 반환값은 `AIGateway` 계약을 통과해야 화면에 표시할 수 있습니다.

## 실행
Godot 4.x → Import → `project.godot` → F5.

## 주요 파일
- `scripts/social_game_state.gd` — 0.0.4 사회관계/질문/회의 계층
- `scripts/main_v004.gd` — 0.0.4 UI 확장
- `docs/AI_CONTRACT.md` — AI 출력 계약
- `docs/CHARACTERS.md` — 8인 캐릭터 Bible
