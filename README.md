# ASTRA 0.0.5 — LOOP MEMORY

AI-native 우주 사회추리 RPG의 다중 Day / 기억 연결 버전입니다.

## 0.0.5 핵심
- 한 번의 투표로 끝나지 않는 **최대 3 Day 조사 루프**
- 격리된 승무원은 다음 Day에서 제외
- 전날 발언/투표/관계/스트레스가 다음 날까지 유지
- Noa 등 NPC가 이전 Day의 발언을 다시 꺼내는 **Memory Echo**
- 최근 NPC 발언을 연결해서 추궁하는 대화 체인
- 초상화 tint 기반 표정 상태: calm / warm / uneasy / angry / afraid / guarded / cold
- 선택형 실제 AI Performance 백엔드
- AI 실패/미실행 시 기존 규칙 기반 대사 100% 유지

## AI 연결 구조
`Godot → ASTRA FastAPI backend → OpenAI Responses API`

API 키는 Godot이나 GitHub에 저장하지 않습니다. `backend/README.md` 참고.

## 실행
Godot 4.x에서 `project.godot`을 Import한 뒤 F5.
AI 백엔드를 켜지 않아도 정상 플레이됩니다.

## 다음 목표 — 0.0.6
- 사건/역할 랜덤화 확대
- 캐릭터 표정별 별도 일러스트 에셋
- AI 회의 발언에도 비동기 연기 적용
- Notebook의 모순 자동 연결선
- 2번째 Incident와 메타 루프 시작
