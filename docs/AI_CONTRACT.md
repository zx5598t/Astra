# ASTRA AI CONTRACT — payload v0.0.6 (game 0.2.0)

AI는 **선택 사항**이며 기본으로 꺼져 있습니다. 게임 설정 → “AI 연기 사용”을 켜고 `backend/`의 서버가 실행 중일 때만 동작합니다.

## 역할
규칙 엔진(`AstraGameSession`)이 먼저 대사를 만들어 화면에 보여 준 뒤, 모델이 같은 의미를 캐릭터 말투로 다시 연기합니다.
검증을 통과하면 대화 기록의 해당 줄 문구만 교체합니다(`apply_ai_line`). 실패·지연·검증 실패 시 규칙 대사가 그대로 남습니다.

## 입력 (`build_ai_context`)
- `npc`: id, name, job, speech_style(말투 설명), social_goal, pressure_response, emotion(stress), trust_player
- `scene`: phase, situation(`player_dialogue`), intent(질문 종류), day, `rule_based_line`(규칙 대사 원문)
- `allowed_fact_refs` / `allowed_facts`: 플레이어가 확보한 단서 id와 본문만
- `allowed_target_ids`: 활동 중인 승무원
- `relationships`: 다른 승무원에 대한 호감도
- `recent_turns`: 이 승무원과의 최근 대화 10줄

## 허용 출력
- `social_act`: answer / deflect / accuse / reassure / interrupt / challenge / refuse
- `target_id`, `claim_refs`(허용된 단서만), `claim_mode`, `display_emotion`
- `relationship_delta`(-0.12~0.12, 제안값일 뿐 적용하지 않음)
- `utterance`(360자 이하)

## 강제 규칙
- 역할(Null), 위치, 단서, 투표, 점수를 만들거나 바꾸지 않는다.
- 허용되지 않은 단서를 인용하지 않는다. `rule_based_line`의 의미(특히 알리바이 장소와 동행)를 바꾸지 않는다.
- 게임은 출력의 `utterance` 문구 외에는 아무것도 반영하지 않는다.
