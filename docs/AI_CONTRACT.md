# ASTRA AI CONTRACT — v0.0.4

## 목적
LLM은 NPC의 연기와 표현을 담당할 수 있지만 사건의 진실을 만들거나 수정할 수 없습니다.

## 입력 컨텍스트
- npc: 이름, 직무, 말투, 사회적 목표, 압박 반응, 감정, 플레이어 신뢰도
- scene: 현재 phase, situation, intent, day
- allowed_fact_refs: NPC가 알 수 있는 canonical fact id
- known_evidence: 현재 공개된 증거
- relationships: NPC가 다른 승무원에게 갖는 관계 상태

## 허용 출력
- social_act: answer / deflect / accuse / reassure / interrupt / challenge / refuse
- target_id
- claim_refs: allowed_fact_refs 안에서만 사용
- display_emotion
- relationship_delta: -0.12 ~ +0.12
- utterance: 최대 360자

## 금지
- TruthEngine 변경
- 숨겨진 역할/범인/증거 생성
- 허용되지 않은 fact ref 인용
- 투표 결과 직접 지정
- 임의의 스탯 대폭 수정
