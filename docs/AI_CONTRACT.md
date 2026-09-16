# ASTRA AI CONTRACT — v0.0.5

## 핵심 원칙
AI는 캐릭터의 **연기와 표현**만 담당한다. TruthEngine, 역할, 증거, 투표, 점수, 승패, 관계 수치의 최종 계산은 게임 코드가 담당한다.

## 클라이언트 → 백엔드
- npc: 이름/직무/말투/사회적 목표/압박 반응/감정/플레이어 신뢰도
- scene: phase/day/situation/intent/생존 인원
- allowed_fact_refs + allowed_facts: 해당 NPC가 말할 수 있는 canonical facts만
- allowed_target_ids: 현재 지목 가능한 생존 승무원
- known_evidence
- relationships: 표현 참고용 관계 상태
- recent_turns: 최근 대화/회의 기억 최대 10개

## 백엔드 → 클라이언트
- social_act
- target_id
- claim_refs
- claim_mode
- display_emotion
- relationship_delta (제안값일 뿐 직접 적용 금지)
- utterance (최대 360자)

## 검증
Godot의 `AIGateway.validate_action()`이 contract version, act, emotion, target, fact refs, 길이, delta 범위를 재검증한다. 실패하면 규칙 기반 대사를 유지한다.
