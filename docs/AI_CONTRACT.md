# ASTRA AI CONTRACT — v0.0.6

## 역할
LLM은 NPC의 표현과 회의 발언을 자연스럽게 연기할 수 있습니다. 사건의 진실과 상태 변경 권한은 없습니다.

## 입력
- npc: 이름, 직무, 말투, 사회적 목표, 압박 반응, 감정, 플레이어 신뢰도
- scene: phase, day, situation, intent, 선택된 회의 대상, 규칙 기반 원문(있을 때)
- allowed_fact_refs / allowed_facts
- allowed_target_ids
- known_evidence
- relationships
- recent_turns

## 허용 출력
- social_act: answer / deflect / accuse / reassure / interrupt / challenge / refuse
- target_id
- claim_refs
- claim_mode: truth / lie / speculation / mistake
- display_emotion
- relationship_delta 제안값(-0.12~+0.12)
- utterance 360자 이하

## 강제 규칙
- Null 역할, 범인, 증거를 새로 만들 수 없음
- 허용되지 않은 fact를 인용할 수 없음
- 투표/점수/승패를 결정할 수 없음
- 관계 delta는 모델 제안일 뿐 엔진이 자동 적용하지 않음
- 공개 회의 AI 대사는 기존 meeting event를 '연기'할 뿐 사건 truth를 바꾸지 않음
- 실패/타임아웃/검증 실패 시 규칙 기반 대사를 그대로 사용
